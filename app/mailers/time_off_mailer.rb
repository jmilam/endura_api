class TimeOffMailer < ApplicationMailer
	def to_manager(to_address, request_type, start_date, end_date, from_user)
		@start_date = start_date.to_date.strftime("%m/%d/%Y")
		@end_date = end_date.to_date.strftime("%m/%d/%Y")
		@from_user = from_user
		@request_type = request_type

  	mail(from: "time_off@enduraproducts.com", to: to_address, subject: "#{request_type} request by #{from_user}.")
  end

  def to_user(to_address, request_type, start_date, end_date, from_user, approved_status, approved_by)
  	@start_date = start_date.to_date.strftime("%m/%d/%Y")
		@end_date = end_date.to_date.strftime("%m/%d/%Y")
		@from_user = from_user
		@request_type = request_type
		@approved_by = approved_by
		@approved_status = approved_status

  	mail(from: "time_off@enduraproducts.com", to: to_address, subject: "#{request_type} request has been #{approved_status}.")
  end
end
