class MarketingMailer < ApplicationMailer
	def notify_tsm_new_order(from_email, to_email, user, order, items)
			@from_email = from_email
			@user = user
			@items = items
			@order = order
			@sum = @items.inject(0) {|sum, item| sum += item['item_total']}
			
			mail(from: "new_order@enduraproducts.com", to: to_email, subject: "New Order placed by #{user}")
	end

	def notify_rep_order_status(from_email, to_email, user, order)
		@from_email = from_email
		@user = user
		@order = order
		@status = @order['accepted'] ? "Approved" : "Denied"

		mail(from: "order_status@enduraproducts.com", to: to_email, subject: "Order ##{@order['id']} was #{@status}")
	end
end
