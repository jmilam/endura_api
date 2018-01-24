class Endura::API < Grape::API
	require 'net/http'
	require 'find'
	before do
		if Rails.env == "test"
			@qadenv = "qadnix"
			@apienv = "testapi"
			@time_off_url = "http://request_off_test.enduraproducts.com"
		elsif Rails.env == "development"
			@qadenv = "qadnix"
			@apienv = "testapi"
		elsif Rails.env == "production"
			@qadenv = "qadprod"
			@apienv = "prodapi"
			@time_off_url = "http://request_off.enduraproducts.com"
		end
	end
	
	resource do
		format :json

		desc 'Login'
		get :login do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapimblogin.p?userid=#{params[:username]}&password=#{params[:password]}&site=#{params[:site_num]}").get
			result = JSON.parse(result, :quirks_mode => true)

			if result["users"][0]["tt_userid"].downcase.match(/good login/)
				pass_result = !result["site"][0]["ttsite"].downcase.match(/good/).nil? ?  "" : "Not a valid site!"
				return {success: true, user_roles: result["roles"][0]["tt_rolename"], site_valid: !result["site"][0]["ttsite"].downcase.match(/good/).nil?, result: pass_result}
			else
				return {success: false, result: result["users"][0]["tt_userid"]}
			end
		end

		desc 'Printer Validation'
		get :validate_printer do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapiprinter.p?printer=#{params[:printer]}&user=#{params[:user]}&site=#{params[:site]}").get
			result = JSON.parse(result, :quirks_mode => true)
			
			if result["success"] == "Good"
				return {success: true}
			else
				return {success: false}
			end
		end

		desc 'Get Tag Information for SHP function'
		get :get_tag_info do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapigetinv1.p?tag=#{params[:tag]}&user=#{params[:user]}&site=#{params[:site]}").get
			result = JSON.parse(result, :quirks_mode => true)

			return result
		end
	end

	resource :bol do
		format :json

		desc 'This searches all availabled BOL files and returns a list of file names'
		get :search do
			files = []
			file_images = []

			Find.find('/media/bol/') do |path|
				next if File.basename(path) == 'bol'
				next if path.match(params[:search_criteria]).nil?

				files << File.basename(path) 
				file_images << Base64.encode64(File.binread(path))
			end

			{files_found: files, file_images: file_images}
		end

		desc 'Pull Image'
		get :pull_file do
	    data = File.binread("/media/bol/#{params[:file_name]}")
	    content_type 'application/octet-stream'
	    body data
	  end

		desc 'This saves signature and creates new pdf and stores'
		post :save_signature do
			begin
				File.open("/media/bol/signatures/#{params[:pdf_file_name]}_shipper_signature.png", 'wb') do |f|
					f.write(params[:bol_signature][:tempfile].read)
				end

				File.open("/media/bol/signatures/#{params[:pdf_file_name]}_carrier_signature.png", 'wb') do |f|
					f.write(params[:carrier_signature][:tempfile].read)
				end

				Prawn::Document.generate("/media/bol/signatures/#{params[:pdf_file_name]}_signature.pdf", :page_size => "A4", :template => "/media/bol/#{params[:pdf_file_name]}") do

					Find.find("/media/bol/signatures/#{params[:pdf_file_name]}_shipper_signature.png") do |img_file|
						image img_file, :at => [0,75], :width => 250 
					end
					Find.find("/media/bol/signatures/#{params[:pdf_file_name]}_carrier_signature.png") do |img_file|
						image img_file, :at => [230,75], :width => 250 
					end
				end

				signature = CombinePDF.load("/media/bol/signatures/#{params[:pdf_file_name]}_signature.pdf").pages[0]
				my_prawn_pdf = CombinePDF.new
				my_prawn_pdf << CombinePDF.load("/media/bol/#{params[:pdf_file_name]}")
				my_prawn_pdf.pages.each { |page| page << signature}
				my_prawn_pdf.save "/media/bol/#{params[:pdf_file_name]}-signed.pdf"

				{success: true}
			rescue StandardError => error
				{success: false, message: error}
			end
		end
	end

	resource :transactions do
		format :json

		desc 'Item Location'
		get :item_location do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapipartloc.p?part=#{params[:item_num]}&user=#{params[:user_id]}").get
			result = JSON.parse(result, :quirks_mode => true)
		end
		
		desc 'PDL'
		get :pdl do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapipul.p?item=#{params[:item_num]}&qty=#{params[:qty_to_move]}&floc=#{params[:from_loc]}&fref=#{params[:tag]}&tloc=#{params[:to_loc]}&fsite=#{params[:to_site]}&tsite=#{params[:from_site]}&user=#{params[:user_id]}&type=#{params[:type]}").get
			result = JSON.parse result, :quirks_mode => true
			
			if !result["success"]
				return {success: false, result: result["status"]}
			else
				return {success: true, result: "Success"}
			end
		end

		desc 'PUL'
		get :pul do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapipul.p?item=#{params[:item_num]}&qty=#{params[:qty_to_move]}&floc=#{params[:from_loc]}&fref=#{params[:tag]}&tloc=#{params[:to_loc]}&fsite=#{params[:to_site]}&tsite=#{params[:to_site]}&user=#{params[:user_id]}&type=#{params[:type]}").get
	    result = JSON.parse(result, :quirks_mode => true)
			
			if result["error"].match(/ERROR/)
				return {success: false, result: result["error"]}
			else
				return {success: true, result: "Success"}
			end
		end

		desc 'PMV'
		get :pmv do
			params[:type] = params[:type].match(/\w+/)[0]
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapipmv.p?fref=#{params[:tag]}&tloc=#{params[:to_loc]}&user=#{params[:user_id]}&type=#{params[:type]}").get	
			result = JSON.parse(result, :quirks_mode => true)
			
			if result["success"]
				return {success: true, result: "Success"}
			else
				return {success: false, result: result["error"]}
			end
		end

		desc 'PCT'
		get :pct do
			#Hardcoded url for testing, make sure add back dynamic when ready for prod
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapipct.p?site=#{params[:to_site]}&tag=#{params[:tag]}&qty=#{params[:qty_to_move]}&user=#{params[:user_id]}").get
			result = JSON.parse(result, :quirks_mode => true)
			
			if result["error"].match(/ERROR/)
				return {success: false, result: result["error"]}
			else
				return {success: true, result: "Success"}
			end
		end

		desc 'PLO Next plo_next_pallet'
		get :plo_next_pallet do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapinextpal.p").get
			result = JSON.parse(result, :quirks_mode => true)
			
			if result["NextPallet"].empty?
				return {success: false, result: result["NextPallet"]}
			else
				return {success: true, result: result["NextPallet"]}
			end
		end

		desc 'PLO'
		get :plo do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapiplo.p?item=#{params[:item_num]}&floc=#{params[:from_loc]}&fsite=#{params[:from_site]}&tsite=#{params[:to_site]}&tloc=#{params[:to_loc]}&tref=#{params[:tag]}&qty=#{params[:qty_to_move]}&user=#{params[:user_id]}&type=PLO").get
			
			result = JSON.parse(result, :quirks_mode => true)
			
			if result["error"].match(/ERROR/)
				return {success: false, result: result["error"]}
			else
				return {success: true, result: "Success"}
			end
		end

		desc 'TPT'
		get :tpt do
			response = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxmbporprt.p?Tag=#{params[:tag]}&Printer=#{params[:printer]}&user=#{params[:user_id]}&site=#{params[:site]}&type=tpt").get
			return {success: true, result: "Label is reprinting..."}
		end

		desc 'GLB'
		get :glb do
			response = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxmbglbprt.p?info=#{params[:remarks]}&Printer=#{params[:printer]}&site=#{params[:site]}&user=#{params[:user_id]}").get
			return {success: true, result: "Label is printing..."}
		end

		desc 'POR'
		get :por do
			begin
				params[:printer] = params[:dev].nil? ? params[:printer] : params[:dev]
				data_string = ""
				unique_key = "#{params[:user]}_#{params[:po_num]}_#{rand(0000..999999)}"
				return_val = nil

				params[:lines].zip(params[:qtys], params[:locations], params[:multipliers]).each do |request_data|
					data_string += "#{request_data[0]},#{request_data[1]},#{request_data[2]},#{request_data[3]},"
				end

				data_string = data_string.chomp(',')
				result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapipornew.p?key=#{unique_key}&dev=#{params[:printer]}&user=#{params[:user]}&po=#{params[:po_num]}&line=#{data_string}&site=#{params[:site]}").get
				error_count = result["Status"].match(/\d+/).nil? ? 0 : (result["Status"].match(/\d+/)[0]).to_i

			  if error_count > 0
					return_val = {success: false, result: result["Error"]}
				end

				if return_val.nil?
					return {success: true, result: "Success", unique_key: "#{unique_key}"}
				else
					return return_value
				end
			rescue => error
				p error
				return error
			end
		end

		desc 'CAR'
		get :car do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapicarcim.p?so=#{params[:so]}&line=#{params[:line]}&cartonbox=#{params[:carton_box]}&PackQty=#{params[:pack_qty]}&PackedQty=#{params[:prev_packed]}&Bulk=#{params[:print]}&printer=#{params[:printer]}&user=#{params[:user]}").get
			result = JSON.parse(result, :quirks_mode => true)
			
			if result["error"].match(/ERROR/)
				return {success: false, result: result["error"]}
			else
				return {success: true, result: "Success"}
			end
		end

		desc 'CTE'
		get :cte do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapicardel.p?carton=#{params[:carton]}&site=#{params[:site]}&user=#{params[:user]}").get
			result = JSON.parse(result, :quirks_mode => true)
			
			if result["error"].downcase.match(/error/)
				return {success: false, result: result["status"]}
			else
				return {success: true, result: "Success"}
			end
		end

		desc 'SHP'
		get :shp do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapishprun.p?string=#{params[:string]}&user=#{params[:user]}").get
			result = JSON.parse(result, :quirks_mode => true)
			
			if result["Status"]
				{success: true, result: ""}
			else
				{success: false, result: result["error"]}
			end
		end

		desc 'BKF'
		get :bkf do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapibkfrun.p?site=#{params[:site]}&part=#{params[:part]}&user=#{params[:user]}&pl=#{params[:prod_line]}&qty=#{params[:qty]}&initials=#{params[:user_initials]}").get
			result = JSON.parse(result, :quirks_mode => true)
		
			return result
		end

		desc 'Get Shipping Lines'
		get :ship_lines do
			#Original JSON API URL
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapishplines.p?so=#{params[:so_number]}&user=#{params[:user]}&site=#{params[:site]}").get
			# result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapishplines1.p?so=#{params[:so_number]}&user=#{params[:user]}&line=#{params[:line_number]}").get
			result = JSON.parse(result, :quirks_mode => true)

			if result["Status"]
				return {success: true, result: result["Lines"]}
			else
				return {success: false, result: result["error"]}
			end
		end

		desc 'Skid Create Cartons'
		get :skid_create_cartons do
			params[:line] = params[:line].nil? ? "All" : params[:line]
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapiskdso.p?SO=#{params[:so_number]}&site=#{params[:site]}&Line=#{params[:line]}&user=#{params[:user]}").get
			result = JSON.parse(result, :quirks_mode => true)
			
			if result["error"].downcase.match(/error/)
				return {success: false, result: result["status"]}
			elsif result["Cartons"].empty?
				return {success: false, result: result["error"]}
			else
				return {success: true, result: result["Cartons"]}
			end
		end

		desc 'Skid Create'
		get :skid_create do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapiskdcreate.p?user=#{params[:user]}&skid=#{params[:skid]}&site=#{params[:site]}&cartons=#{params[:cartons]}").get
			result = JSON.parse(result, :quirks_mode => true)

			if result["error"].match(/PO not found/)
				return {success: false, result: result["error"]}
			else
				return {success: true, result: result}
			end
		end
		
		desc 'Validate PO Number'
		get :po_details do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapipolines.p?po=#{params[:po_number]}&user=#{params[:user]}").get
			result = JSON.parse(result, :quirks_mode => true)
			if result["error"].match(/PO not found/)
				return {success: false, result: result["error"]}
			else
				return {success: true, result: result}
			end
		end

		desc 'Tag Details'
		get :tag_details do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapigetinv.p?tag=#{params[:tag]}&user=#{params[:user]}").get
			result = JSON.parse(result, :quirks_mode => true)
			@success = false

			unless result["success"] == "Tag Loc Not Found"
				@success = true
			end

			return {success: @success, result: result["INFO"].last}
		end

		desc 'Sales Order Details'
		get :sales_order_details do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapicardis.p?so=#{params[:so_number]}&user=#{params[:user]}").get
			
			result = JSON.parse(result, :quirks_mode => true)

			if result["status"] == "Good"
				result["Lines"].delete_if {|line| line["ttli"].to_s != params[:line_number]}
			else
				result
			end

			return result
		end

		desc 'Item Lookup'
		get :item_lookup do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapigetlocs.p?part=#{params[:part]}&site=#{params[:site]}&user=#{params[:user]}").get
			result = JSON.parse(result, :quirks_mode => true)

			return result
		end

		desc 'Carton Box Validation'
		get :carton_box_validation do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapicarbox.p?box=#{params[:box]}&user=#{params[:user]}").get
			result = JSON.parse(result, :quirks_mode => true)

			return result
		end

		desc 'Check if skid exist'
		get :skid_exist do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapiskdexist.p?userid=#{params[:user]}&skid=#{params[:skid]}&site=#{params[:site]}").get
			result = JSON.parse(result, :quirks_mode => true)

			return result
		end

		desc 'Get Product lines associated to an item number'
		#http://qadnix.endura.enduraproducts.com/cgi-bin/testapi/xxapibkfpl.p?site=2000&part=73Z7815BFS-2-72&user=mdraughn

		get :bkf_product_lines do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapibkfpl.p?site=#{params[:site]}&part=#{params[:part]}&user=#{params[:user]}").get
			result = JSON.parse(result, :quirks_mode => true)

			return result
		end
	end

	resource :cardinal_printing do
		format :json

		desc 'Skid Label Printing'
		get :skid_label do
			tries = 0

			begin
				#Hardcoded url for testing, make sure add back dynamic when ready for prod
        response = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxmbskdprt.p?Site=#{params[:site]}&SKID=#{params[:skid_num]}&Printer=#{params[:printer]}&user=#{params[:user_id]}").get

        return {success: true, result: "Success"}
      rescue
        if tries == 1
          break
        else
          if tries < 1
          	tries += 1
          	retry
          else
          	return {success: false, result: "Webspeed error"}
          end 
        end
      end
		end
		
		desc 'Print label by Tag Number'
		get :print_label do
			response = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxmbporprt.p?Tag=#{params[:tag]}&Printer=#{params[:printer]}&user=#{params[:user_id]}&site=#{params[:site]}&#{params[:trans_type].match(/[^()]+/)[0].strip}").get
		end
	end


	resource :picklist do
		format :json

		desc 'sillFG'
		get :sillfg do
			formatted_return = {data: []}
			counter = 1
		  result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapisccutlist.p").get
			result = JSON.parse(result, :quirks_mode => true)
			result["cutlist"].each do |item|
				#Downcases keys in order for Ember.js model to recognize
				item = Hash[item.map{ |k, v| [k.downcase, v] }]
				formatted_return[:data].push({id: counter, type: 'bookmark', attributes: item})
				counter += 1
			end

			return formatted_return
		end
	end

	resource :sro do
		format :json

		desc 'Order Entry'
		get :order_entry do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapioesrodashboard.p?start=#{params[:start]}&end=#{params[:end]}&srodetailfrom=#{params[:start]}&srodetailto=#{params[:end]}&type=#{params[:dept]}").get
			result = JSON.parse(result)
			
			result
		end
	end

	resource :email do
		format :json

		resource :order_entry do
			desc 'report_card'
			post :report_card do
				chart_data = JSON.parse(params[:chart_data].to_json, :quirks_mode => true)
				
				if OeMailer.report_card(params[:from], params[:to], params[:subject], params[:body], params[:file], eval(chart_data)[:data]).deliver
			  	return {success: true}
			  else
			  	return {success: false}
			  end
			end
		end

		resource :irds do
			desc 'export'
			post :export do
				export_data = Base64.decode64(params[:export_data])
				if IrdsMailer.export_to_csv(params[:from], params[:to], params[:subject], export_data, params[:search_criteria]).deliver
					return {success: true}
				else
					return {success: false}
				end
			end
		end

		resource :salesforce do 
			desc 'sales call xls'
			post :export do 
				if SalesforceMailer.sales_call_export(params[:from], params[:to], params[:subject], params[:body], params[:file]).deliver
						return {success: true}
			  else
			  	return {success: false}
			  end
			end
		end

		resource :time_off_request do
			desc 'Send email to manger w/ new request link'
		  post :manager_update do 
		  	TimeOffMailer.to_manager(params[:to_email], params[:request_type], params[:start_date], params[:end_date], params[:from_user]).deliver
		  end

		  desc "Send email to user w/ manager response"
		  post :user_update do
		  	approve_status = params[:approved] == "true" ? "Approved" : "Denied"
		  	TimeOffMailer.to_user(params[:to_email], params[:request_type], params[:start_date], params[:end_date], params[:from_user], approve_status, params[:approved_by]).deliver
		  end

		  desc "Send email to maanger when time off is tomorrow"
		  get :tomorrow_requests do
		  	result = HttpRequest.new("#{@time_off_url}/time_off_request/tomorrow_requests.json").get
				result = JSON.parse(result)
				TimeOffMailer.notify_dept(params[:to_email], result["requests"]).deliver
		  end
		end

		resource :marketing do
			desc 'Send email to tsm w/ link to Approve/Reject Order'
		  post :tsm_notification do
		  	MarketingMailer.notify_tsm_new_order(params[:from_email], params[:to_email], params[:user], JSON.parse(params[:order]), JSON.parse(params[:items])).deliver
		  	{success: true}
		  end

		  desc 'Send email to rep w/ link to view accepted/rejected'
		  post :rep_notification do
		  	MarketingMailer.notify_rep_order_status(params[:from_email], params[:to_email], params[:user], JSON.parse(params[:order])).deliver
		  	{success: true}
		  end

		  desc 'Send email for past due tsm approve/deny emails'
		  post :tsm_past_due_notification do
		  	MarketingMailer.notify_tsm_past_due_orders(params[:from_email], params[:to_email], params[:user], JSON.parse(params[:order]), JSON.parse(params[:items])).deliver
		  	{success: true}
		  end

		  desc 'Send email nightly for daily order overview'
		  post :order_overview_by_date_range do
		  	MarketingMailer.order_overview_by_date_range(JSON.parse(params[:orders]),
						  																			 JSON.parse(params[:customers]),
						  																			 JSON.parse(params[:order_items]),
						  																			 JSON.parse(params[:item_references])).deliver
		  end

		  desc 'Send email for Catalog Request when order checked out'
		  post :new_catalog_request do
		  	MarketingMailer.new_catalog_request(JSON.parse(params[:request])).deliver
		  	{success: true}
		  end

		  desc 'Send email for Image Request when order checked out'
		  post :new_image_request do
		  	MarketingMailer.new_image_request(params[:order_id]).deliver
		  	{success: true}
		  end
		end

		resource :reminder do
			desc 'Email reminder of Upcoming Week time off requests'
			post :upcoming_week_off do
				requests = JSON.parse(params[:requests])
				managers = JSON.parse(params[:managers])
				users = JSON.parse(params[:users])
				payroll_users = JSON.parse(params[:payroll_users])

				requests.each do |r|
					manager = managers.select {|manager| manager['id'] == r['manager_id']}[0]
					user = users.select {|user| user['id'] == r['user_id']}[0]
					mail = TimeOffMailer.upcoming_time_off r, manager, user 
					mail.deliver
				end

				managers.each do |m|
					emp_req = requests.select {|r| r['manager_id'] == m['id']}
					mail = TimeOffMailer.upcoming_time_off_manager m, emp_req, users
					mail.deliver
				end

				payroll_users.each do |pu|
					mail = TimeOffMailer.upcoming_time_off_payroll pu, requests, users
					mail.deliver
				end
			end

			desc 'Email update to Manager on July 1 about remaining balances over 112 hours'
			post :users_over_112 do
				remaining_bal = eval params[:data]
				remaining_bal.each do |key, value|
					mail = TimeOffMailer.over_112_hours_to_manager key, value 
					mail.deliver
				end
			end
		end
	end
end