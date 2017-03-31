class Endura::API < Grape::API
	require 'net/http'
	before do
		if Rails.env == "test"
			@qadenv = "qadnix"
			@apienv = "testapi"
			@time_off_url = "http://request_off_test.enduraproducts.com"
		elsif Rails.env == "development"
			@qadenv = "qadnix"
			@apienv = "devapi"
			@time_off_url = "http://localhost:3001"
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
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapimblogin.p?userid=#{params[:username]}&password=#{params[:password]}&site=#{params[:site]}").get
			result = JSON.parse(result, :quirks_mode => true)
			if result["users"][0]["tt_userid"].downcase.match(/good login/)
				return {success: true, result: result["users"][0]["tt_userid"]}
			else
				return {success: false, result: result["users"][0]["tt_userid"]}
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
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapipul.p?item=#{params[:item_num]}&qty=#{params[:qty_to_move]}&floc=#{params[:from_loc]}&fref=#{params[:tag]}&tloc=#{params[:to_loc]}&fsite=2000&tsite=2000&user=#{params[:user_id]}&type=#{params[:type]}").get
			result = JSON.parse(result, :quirks_mode => true)
			
			if result["error"].match(/ERROR/)
				return {success: false, result: result["error"]}
			else
				return {success: true, result: "Success"}
			end
		end

		desc 'PUL'
		get :pul do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapipul.p?item=#{params[:item_num]}&qty=#{params[:qty_to_move]}&floc=#{params[:from_loc]}&fref=#{params[:tag]}&tloc=#{params[:to_loc]}&fsite=2000&tsite=2000&user=#{params[:user_id]}&type=#{params[:type]}").get
	    result = JSON.parse(result, :quirks_mode => true)
			
			if result["error"].match(/ERROR/)
				return {success: false, result: result["error"]}
			else
				return {success: true, result: "Success"}
			end
		end

		desc 'PMV'
		get :pmv do
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapipmv.p?fref=#{params[:tag]}&tloc=#{params[:to_loc]}&user=#{params[:user_id]}&type=#{params[:type]}").get	
			result = JSON.parse(result, :quirks_mode => true)
			
			if result["error"].match(/ERROR/)
				return {success: false, result: result["error"]}
			else
				return {success: true, result: "Success"}
			end
		end

		desc 'PCT'
		get :pct do
			#Hardcoded url for testing, make sure add back dynamic when ready for prod
			result = HttpRequest.new("http://qadnix.endura.enduraproducts.com/cgi-bin/devapi/xxapipct.p?item=#{params[:item_num]}&site=#{params[:to_site]}&loc=#{params[:to_loc]}&lot=&tag=#{params[:tag]}&qty=#{params[:qty_to_move]}&remarks=&eff=#{Date.today.strftime("%m/%d/%Y")}&Cr=&CrSite=&user=#{params[:user_id]}").get
			# result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapipct.p?item=212100-2-36&site=2000&loc=DISDD-31&lot=na&tag=02143228&qty=1&remarks=test&eff=02/13/2017&Cr=%22%22&CrSite=2000&user=mdraughn")
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
	end

	resource :cardinal_printing do
		format :json

		desc 'Skid Label Printing'
		get :skid_label do
			tries = 0

			begin
				#Hardcoded url for testing, make sure add back dynamic when ready for prod
        response = HttpRequest.new("http://qadnix.endura.enduraproducts.com/cgi-bin/devapi/xxmbskdprt.p?Site=#{params[:site]}&SKID=#{params[:skid_num]}&Printer=#{params[:printer]}&user=#{params[:user_id]}").get
        # response = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxmbskdprt.p?Site=#{params[:site]}&SKID=#{params[:skid]}&Printer=#{params[:printer]}&user=#{params[:user]}").get

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
			desc 'Send email to maanger w/ new request link'
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
		end

		resource :reminder do
			desc 'Email reminder of Upcoming Week time off requests'
			post :upcoming_week_off do
				requests = JSON.parse(params[:requests])
				managers = JSON.parse(params[:managers])
				users = JSON.parse(params[:users])
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