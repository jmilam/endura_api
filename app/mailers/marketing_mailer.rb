class MarketingMailer < ApplicationMailer
	def notify_tsm_new_order(from_email, to_email, user, order, items)
			@url = Rails.env == "production" ? "http://marketing.enduraproducts.com" : "http://marketing_test.enduraproducts.com"
			@from_email = from_email
			@from_email << ", dsavage@enduraproducts.com"
			@user = user
			@items = items
			@order = order
			@sum = @items.inject(0) {|sum, item| sum += item['item_total']}
			
			mail(from: "new_order@enduraproducts.com", to: to_email, cc: from_email, subject: "New Order placed by #{user}")
	end

	def notify_rep_order_status(from_email, to_email, user, order)
		@url = Rails.env == "production" ? "http://marketing.enduraproducts.com" : "http://marketing_test.enduraproducts.com"
		@from_email = from_email
		@user = user
		@order = order
		@status = @order['accepted'] ? "Approved" : "Denied"

		mail(from: "order_status@enduraproducts.com", to: to_email, cc: 'dsavage@enduraproducts.com' subject: "Order ##{@order['id']} was #{@status}")
	end
end
