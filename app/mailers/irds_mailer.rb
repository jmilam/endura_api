class IrdsMailer < ApplicationMailer
	def export_to_csv(from, to, subject, export_data, search_criteria)
		spreadsheet = StringIO.new
		Spreadsheet.client_encoding = 'UTF-8'
		book = Spreadsheet::Workbook.new
		sheet1 = book.create_worksheet :name => "Report Card #{Date.today.strftime("%m-%d-%Y")}"
		sheet2 = book.create_worksheet :name => "Search Criteria"
		sheet1.row(0).replace ["Item Number", "Product Family" ,"Commodity","Family","Group","Sub-Group","Finish","Color","Style","Customer",
													 "Modified","CompletedBy","Description","Description 1","Buyer/Planner","Warehouse","Status","Purchase/Manufacture",
													 "Group 1","Item Type","Location","Site","PO Site","Prod Line","Purchase Lead Time","Safety Stock","TotalINV","Usage90",
													 "Usage180","Usage365","EstWklyUsage","ESTMTHLYUSAGE","Unit Std Cost","Total Std Cost","DSI","Excess","No Name",
													 "created_at","Usage30","Avg30DayDlyUsage","Avg 90 Day Dly Usage","Avg 180 Day Dly Usage","Avg 365 Day Dly Usage",
													 "Base Line","Run Out Date","Supply Order Qty","Supply Rcvd Qty","Supply Open Qty","Supply Past Due Open Qty",
													 "Supply Max PO Cost","Supply Weeks Qty Daily Base Line","Manual MRP Ext Baseline Unit Cost","ONH2000","ONH3000",
													 "ONH4300","ONH5000","Inv Site","Total WIP Qty","Inv Turns", "Days On Hand"]
		sheet2.row(0).replace ["Site", "Product Family", "Commodity", "Group", "SubGroup", "Finish", "Color", "Style", "Customer", "Search Date"]
		
		row_count = 0
		export_data.split("\n").each_with_idx do |row_data, idx|			
			unless row_count == 0 
				sheet1.row(row_count).replace row_data.split(",")
				row = sheet1.row(row_count)

				(26, 27, 56, 57, 58).each do |idx|
					row[idx] = row[idx].to_i
				end

				(32, 33, 59).each do |idx|
					row[idx] = row[idx].to_f.round(2)
				end
			end
			row_count += 1
		end

		formatted_data = search_criteria.split(",")
		0.upto(formatted_data.count) do |column_num|
		  sheet2[1, column_num.to_i] = formatted_data[column_num]
		end

		file_loc = "public/irds/Irds-Export-#{Date.today.strftime("%m-%d-%Y")}.xls"
		book.write file_loc

		attachments["irds-export.xls"] = File.read(file_loc) unless file_loc.nil?
  	mail(from: from, to: to, subject: subject)
  	File.delete(file_loc)
  end
end
