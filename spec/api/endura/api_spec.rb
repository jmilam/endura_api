require 'rails_helper'

describe Endura::API do

  def parse_response_to_json(response)
    json = JSON.parse response, :quirks_mode => true
    JSON.parse response
  end

  describe 'PDL' do
    describe 'possible failures' do 
      before :each do
        @url = '/api/endura/transactions/pdl'
      end

      describe 'should return error' do
        after :each do
          json = parse_response_to_json response.body
          expect(response.status).to eq 200
          expect(json['success']).to eq false
          expect(json["result"]).to_not eq nil
        end

        it 'has incorrect item number' do
          get @url, params: {item_num: "8225626HV-1-3",
                             qty_to_move: "150",
                             from_loc: "FAH-31",
                             tag: "02181457",
                             to_loc: "2400",
                             user_id: "jmilam",
                             type: "pdl"}
        end

        it 'has incorrect from location' do
          get @url, params: {item_num: "8225626HV-1-36",
                             qty_to_move: "150",
                             from_loc: "FU-17",
                             tag: "02181457",
                             to_loc: "2400",
                             user_id: "jmilam",
                             type: "pdl"}
        end

        it 'has incorrect tag number' do
          get @url, params: {item_num: "8225626HV-1-36",
                             qty_to_move: "150",
                             from_loc: "FAH-31",
                             tag: "2-227457",
                             to_loc: "2400",
                             user_id: "jmilam",
                             type: "pdl"}
        end
      end

      describe 'should be successful' do
        it 'should perform transaction with no errors' do 
          get @url, params: {item_num: "8225626HV-1-36",
                             qty_to_move: "150",
                             from_loc: "FAH-31",
                             tag: "02181457",
                             to_loc: "2400",
                             user_id: "jmilam",
                             type: "pdl"}

          json = parse_response_to_json response.body
          expect(response.status).to eq 200
          expect(json['success']).to eq true
          expect(json['result']).to eq 'Success'
        end
      end
    end
  end

  describe 'PUL' do
    before :each do
      @url = '/api/endura/transactions/pul'
    end

    it 'has incorrect tag number' do
      get @url, params: {item_num: "8225626HV-1-36",
                         qty_to_move: "1",
                         from_loc: "FAH-31",
                         tag: "2-227457",
                         to_loc: "2400",
                         user_id: "jmilam",
                         type: "pul"}

      json = parse_response_to_json response.body 
      expect(response.status).to eq 200
      expect(json['success']).to eq false
      expect(json["result"]).to_not eq nil
    end

    describe 'should be successful' do
      it 'should perform transaction with no errors' do 
        get @url, params: {item_num: "8225626HV-1-36",
                           qty_to_move: "1",
                           from_loc: "FAH-31",
                           tag: "02181457",
                           to_loc: "2400",
                           user_id: "jmilam",
                           type: "pul"}

        json = parse_response_to_json(response.body)
        expect(response.status).to eq 200
        expect(json['success']).to eq true
        expect(json["result"]).to eq "Success"
      end
    end
  end

  describe 'PMV' do
    before :each do
      @url = '/api/endura/transactions/pmv'
    end

    describe 'possible failures' do 
      describe 'should return error' do
        it 'has incorrect to location' do
          get @url, params: {tag: "02181457",
                             to_loc: "FU-17",
                             user_id: "jmilam",
                             type: "pmv"}

          json = parse_response_to_json response.body
          expect(response.status).to eq 200
          expect(json['success']).to eq false
          expect(json["result"]).to_not eq nil
        end

        it 'has incorrect tag number' do
          get @url, params: {tag: "2-227457",
                             to_loc: "2400",
                             user_id: "jmilam",
                             type: "pmv"}

          json = parse_response_to_json response.body
          expect(response.status).to eq 200
          expect(json['success']).to eq false
          expect(json["result"]).to_not eq nil
        end
      end
    end
  end

  describe 'PCT' do
  end

  describe 'PLO' do
    describe 'get next pallet number' do
      before :each do
        @url = '/api/endura/transactions/plo_next_pallet'
      end

      it 'should return JSON data' do 
        get @url, params: {}
        expect(response.status).to eq 200
        json = parse_response_to_json response.body
        expect(json["result"]).to_not eq nil
      end
    end

    describe 'possible errors' do
      before :each do
        @url = '/api/endura/transactions/plo'
      end

      after :each do
        json = parse_response_to_json response.body
        expect(response.status).to eq 200
        expect(json['success']).to eq false
        expect(json["result"]).to_not eq nil
      end

      it 'should return error b/c item number not valid' do
        get @url, params: {item_num: "8225626HV-1-3",
                           qty_to_move: "1",
                           from_loc: "2400",
                           from_site: "2000",
                           to_site: "2000",
                           to_loc: "FAH-31",
                           user_id: "jmilam",
                           type: "plo"}
      end

      it 'should return error b/c fom location not valid' do
        get @url, params: {item_num: "8225626HV-1-30",
                           qty_to_move: "1",
                           from_loc: "jm-27",
                           from_site: "2000",
                           to_site: "2000",
                           to_loc: "FAH-31",
                           user_id: "jmilam",
                           type: "plo"}
      end
    end

    describe 'successful request' do
      before(:each) do
        @url = '/api/endura/transactions/plo'
      end

      it 'should return no error and complete transaction' do
        get @url, params: {item_num: "8225626HV-1-32",
                           qty_to_move: "1",
                           from_loc: "2400",
                           from_site: "2000",
                           to_site: "2000",
                           to_loc: "FAH-31",
                           user_id: "jmilam",
                           type: "plo"}

        json = parse_response_to_json response.body
        expect(response.status).to eq 200
        expect(json['success']).to eq true
        expect(json['result']).to eq 'Success'
      end

    end
  end

  describe 'Tag Details' do
    describe 'get tag details' do
      before :each do
        @url = '/api/endura/transactions/tag_details'
      end

      it 'should return tag details' do
        get @url, params: {tag: "02233582",
                           user: "mdraughn"}

        json = parse_response_to_json response.body
        tag_info = json["INFO"]
        expect(tag_info.first["ttitem"]).to eq "139900-01"
        expect(tag_info.first["ttdesc1"]).to eq "FINGER JOINT and RF GLUE"
        expect(tag_info.first["tttag"]).to eq "02233582"
        expect(tag_info.first["ttsite"]).to eq "4300"
        expect(tag_info.first["ttwh"]).to eq "STK"
        expect(tag_info.first["ttqtyloc"]).to eq 2512.0
        expect(tag_info.first["ttloc"]).to eq "3150"

      end
    end
  end

  describe 'BKF' do
  end

  describe 'Skid Print' do
    describe 'ability to print Skid label' do
      before :each do
        @url = '/api/endura/cardinal_printing/skid_label'
      end

      it 'should print Skid label' do
        get @url, params: {site: "2000",
                           skid: "s01290018",
                           printer: "3600it",
                           user: "mdraughn"}

        json = parse_response_to_json response.body
        expect(json["success"]).to eq true
        expect(json["result"]).to eq "Success"
      end
    end
  end

  describe 'Emails' do
    describe 'order entry emails' do
      before :each do
        @url = '/api/endura/email/order_entry/report_card'
      end

      it 'should send email without an attachment' do
        
        post @url, params: {from: "jmilam@enduraproducts.com",
                            to: "jmilam@enduraproducts.com",
                            subject: "dashboard",
                            body: "This is from the sro order entry email"}

        json = parse_response_to_json response.body
        expect(response.status).to eq 201 #Created
        expect(json["success"]).to eq true
      end
    end

    describe 'Reminders' do
      describe 'Sends an email of all upcoming week off' do
        before :each do 
          @url = '/api/endura/email/reminder/upcoming_week_off'
        end

        it 'should send email for upcoming week off' do
        end
      end
    end
  end
end
