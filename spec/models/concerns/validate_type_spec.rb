require 'rails_helper'

RSpec.describe ValidateType, :type => :model do
	before(:all) do
		@vt_obj = ValidateType.new
	end

  it "should make not valid type to valid type" do
    expect(@vt_obj.isNumber("14").class).to eq(Fixnum)
    expect(@vt_obj.isNumber("14")).to eq(14)
  end

  it "should keep valid type valid" do
    expect(@vt_obj.isNumber(14).class).to eq(Fixnum)
    expect(@vt_obj.isNumber(14)).to eq(14)
  end

  it "should raise type error" do
  	ret_value = @vt_obj.isNumber("i17")
  	expect(ret_value.class).to eq(Hash)
  	expect(ret_value[:error]).to eq("TypeError")
  end

end