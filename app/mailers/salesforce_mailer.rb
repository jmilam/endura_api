class SalesforceMailer < ApplicationMailer
	def sales_call_export(from, to, subject, body, file)
  	attachments["salesforce_export.xls"] = File.read(file.tempfile) unless file.nil?

  	mail(from: from, to: to, subject: subject)
  end
end
