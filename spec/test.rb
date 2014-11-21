require "json"
require "selenium-webdriver"
require "rspec"
include RSpec::Expectations

SHARED_PASSWORD="kagetora"
USER1_PASSWORD="karuta01"
USER2_PASSWORD="karuta02"
USER3_PASSWORD="karuta03"

describe "Test" do

  before(:each) do
    @driver = Selenium::WebDriver.for :firefox
    @base_url = "http://localhost:9292/"
    @accept_next_alert = true
    @driver.manage.timeouts.implicit_wait = 10
    @driver.manage.delete_all_cookies
    @verification_errors = []
  end
  
  after(:each) do
    @driver.quit
    expect(@verification_errors).to be_empty
  end
  
  it "test_login" do
    @driver.get(@base_url + "/")
    @driver.find_element(:css, 'input[type="password"]').send_keys SHARED_PASSWORD
    @driver.find_element(:xpath, "//input[@value='GO']").click
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:id, "initials")).select_by(:value, "-1")
    @driver.find_element(:css, "input[type=\"password\"]").send_keys SHARED_PASSWORD
    @driver.find_element(:xpath, "//input[@value='GO']").click
    expect(element_present?(:css, ".top-message")).to be(true)
  end
  
  def element_present?(how, what)
    @driver.find_element(how, what)
    true
  rescue Selenium::WebDriver::Error::NoSuchElementError
    false
  end
  
  def alert_present?()
    @driver.switch_to.alert
    true
  rescue Selenium::WebDriver::Error::NoAlertPresentError
    false
  end
  
  def verify(&blk)
    yield
  rescue ExpectationNotMetError => ex
    @verification_errors << ex
  end
  
  def close_alert_and_get_its_text(how, what)
    alert = @driver.switch_to().alert()
    alert_text = alert.text
    if (@accept_next_alert) then
      alert.accept()
    else
      alert.dismiss()
    end
    alert_text
  ensure
    @accept_next_alert = true
  end
end
