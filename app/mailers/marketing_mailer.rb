class MarketingMailer < ApplicationMailer
	def notify_tsm_new_order(from_email, to_email, user, order, items)
			@url = Rails.env == "production" ? "http://marketing.enduraproducts.com" : "http://marketing-test.enduraproducts.com"
			@from_email = from_email
			@user = user
			@items = items
			@order = order
			@sum = @items.inject(0) {|sum, item| sum += item['item_total']}
			
			mail(from: "new_order@enduraproducts.com", to: to_email, cc: from_email, subject: "New Order placed by #{user}")
	end

	def notify_rep_order_status(from_email, to_email, user, order)
		@url = Rails.env == "production" ? "http://marketing.enduraproducts.com" : "http://marketing-test.enduraproducts.com"
		@from_email = from_email
		@user = user
		@order = order
		@status = @order['accepted'] ? "Approved" : "Denied"

		mail(from: "order_status@enduraproducts.com", to: to_email, subject: "Order ##{@order['id']} was #{@status}")
	end

	def notify_tsm_past_due_orders(from_email, to_email, user, order, items)
			@url = Rails.env == "production" ? "http://marketing.enduraproducts.com" : "http://marketing-test.enduraproducts.com"
			@from_email = from_email
			@user = user
			@items = items
			@order = order
			@sum = @items.inject(0) {|sum, item| sum += item['item_total']}
			
			mail(from: "past_due_orders@enduraproducts.com", to: to_email, cc: from_email, subject: "Please view past due order not accepted yet for #{user}")
	end

	def daily_order_overview(orders, customers)
		@url = Rails.env == "production" ? "http://marketing.enduraproducts.com" : "http://marketing-test.enduraproducts.com"
		@orders = orders
		@customers = customers
		
		mail(from: "daily_order_overview@enduraproducts.com", to: 'jasonlmilam@gmail.com', subject: "Daily Order Overview for #{Date.today}")
	end

	def new_catalog_request(catalog_request_ids)
		@url = Rails.env == "production" ? "http://marketing.enduraproducts.com" : "http://marketing-test.enduraproducts.com"
		catalog_request_ids.each do |id|
			@id = id

			mail(from: "marketing_ecommerce@enduraproducts.com", to: "wrike+into178296025@wrike.com", cc: 'marketing@enduraproducts.com, kcoltrane@enduraproducts.com', subject: "[A new Catalog Request form has been submitted.]")
		end
	end

	def new_image_request(order_id)
		@url = Rails.env == "production" ? "http://marketing.enduraproducts.com" : "http://marketing-test.enduraproducts.com"
		@order_id = order_id

		mail(from: "marketing_ecommerce@enduraproducts.com", to: "wrike+into178296356@wrike.com", cc: 'marketing@enduraproducts.com, kcoltrane@enduraproducts.com', subject: "[A new Image Request has been submitted.]")
	end
end
