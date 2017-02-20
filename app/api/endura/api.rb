class Endura::API < Grape::API
	before do
		if Rails.env == "test"
			@qadenv = "qadnix"
			@apienv = "testapi"
		elsif Rails.env == "development"
			@qadenv = "qadnix"
			@apienv = "devapi"
		elsif Rails.env == "production"
			@qadenv = "qadprod"
			@apienv = "prodapi"
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
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapipmv.p?fref=#{params[:tag]}&loc=#{params[:to_loc]}&user=#{params[:user_id]}&type=#{params[:type]}").get	
			result = JSON.parse(result, :quirks_mode => true)
			
			if result["error"].match(/ERROR/)
				return {success: false, result: result["error"]}
			else
				return {success: true, result: "Success"}
			end
		end

		desc 'PCT'
		get :pct do
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
			pallet = JSON.parse(HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapinextpal.p").get)
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapiplo.p?item=#{params[:item_num]}&floc=#{params[:from_loc]}&fsite=#{params[:from_site]}&tsite=#{params[:to_site]}&tloc=#{params[:to_loc]}&tref=#{pallet['NextPallet']}&qty=#{params[:qty_to_move]}&user=#{params[:user_id]}&type=PLO").get
			
			result = JSON.parse(result, :quirks_mode => true)
			
			if result["error"].match(/ERROR/)
				return {success: false, result: result["error"]}
			else
				return {success: true, result: "Success"}
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
			result = HttpRequest.new("http://#{@qadenv}.endura.enduraproducts.com/cgi-bin/#{@apienv}/xxapioesrodashboard.p?start=#{params[:start]}&end=#{params[:end]}&srodetailfrom=#{params[:start]}&srodetailto=#{params[:end]}").get
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
				p params[:file]
				if SalesforceMailer.sales_call_export(params[:from], params[:to], params[:subject], params[:body], params[:file]).deliver
						return {success: true}
			  else
			  	return {success: false}
			  end
			end
		end
	end
end