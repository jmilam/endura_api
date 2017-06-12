class OeMailer < ApplicationMailer
	def report_card(from, to, subject, body, file, chart_data=[[]])
  	attachments["oe.xls"] = File.read(file.tempfile) unless file.nil?
  	@chart_data = chart_data

  	mail(from: from, to: to, subject: subject)
  end
end
