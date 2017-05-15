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

  def notify_dept(to_address, data)
  	@requests = data
  	mail(from: "time_off@enduraproducts.com", to: to_address, subject: "Employees not here tomorrow.")
  end

  def upcoming_time_off(request, user, manager)
  	@request = request
  	@user = user

  	mail from: "time_off@enduraproducts.com", to: user['email'], subject: "Don't forget you're #{request['time_off_type.downcase']} next week!"
  end

  def upcoming_time_off_manager(manager, requests, users)
  	@requests = requests
  	@users = users
  	mail from: "time_off@enduraproducts.com", to: manager['email'], subject: "You have employees off this week."
  end

  def upcoming_time_off_payroll(user, requests, users)
    p user
    @requests = requests
    @users = users
    mail from: "time_off@enduraproducts.com", to: user['email'], subject: "All employees off this week."
  end

  def over_112_hours_to_manager(manager, users)
  	@users = users
  	mail from: "time_off@enduraproducts.com", to: manager, subject: "Employees with over 112 hours remaining."
  end
end
