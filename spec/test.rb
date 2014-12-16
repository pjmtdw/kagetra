require "./conf"
require "selenium-webdriver"
require "rspec"
include RSpec::Expectations

DB_NAME="test_kagetra"
SHARED_PASSWORD="kagetora"
USER1_PASSWORD="karuta01"
USER2_PASSWORD="karuta02"
USER3_PASSWORD="karuta03"

describe "Test" do

  before(:each) do
    @driver = Selenium::WebDriver.for :firefox
    @wait = Selenium::WebDriver::Wait.new(timeout:10)
    @base_url = "http://localhost:9292"
    @accept_next_alert = true
    @driver.manage.timeouts.implicit_wait = 10
    @driver.manage.delete_all_cookies
    @verification_errors = []
  end
  
  after(:each) do
    @driver.quit
    expect(@verification_errors).to be_empty
  end
  
  def do_login
    @driver.get(@base_url + "/")
    @driver.find_element(:css, 'input[type="password"]').send_keys SHARED_PASSWORD
    @driver.find_element(:xpath, "//input[@value='GO']").click
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:id, "initials")).select_by(:value, "-1")
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:id, "user-names")).select_by(:value, "1")
    @driver.find_element(:css, 'input[type="password"]').send_keys SHARED_PASSWORD
    @driver.find_element(:xpath, "//input[@value='GO']").click
    @wait.until { @driver.find_element(:css, ".top-message") }
  end

  it "test_login" do
    do_login
    expect(element_present?(:css, ".top-message")).to be(true)
    @wait.until { @driver.find_element(:css, ".login-message").displayed? }
  end

  it "test_admin_useradd" do
    do_login
    @driver.get(@base_url + "/admin")
    @driver.find_element(:id, "add-user").click
    @driver.find_element(:name, "name").send_keys "綾瀬 千早"
    @driver.find_element(:name, "furigana").send_keys "あやせ ちはや"
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, "attr_2")).select_by(:text, "女")
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, "attr_3")).select_by(:text, "2年")
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, "attr_4")).select_by(:text, "A級")
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:name, "attr_5")).select_by(:text, "4")
    @driver.find_element(:xpath, "(//input[@name='name'])[2]").send_keys "真島 太一"
    @driver.find_element(:xpath, "(//input[@name='furigana'])[2]").send_keys "ましま たいち"
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "(//select[@name='attr_3'])[2]")).select_by(:text, "2年")
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "(//select[@name='attr_4'])[2]")).select_by(:text, "B級")
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "(//select[@name='attr_5'])[2]")).select_by(:text, "2")
    @driver.find_element(:xpath, "(//input[@name='name'])[3]").send_keys "西田 優征"
    @driver.find_element(:xpath, "(//input[@name='furigana'])[3]").send_keys "にしだ ゆうせい"
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "(//select[@name='attr_3'])[3]")).select_by(:text, "2年")
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "(//select[@name='attr_4'])[3]")).select_by(:text, "B級")
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "(//select[@name='attr_5'])[3]")).select_by(:text, "2")
    @driver.find_element(:xpath, "(//input[@name='name'])[4]").send_keys "駒野 勉"
    @driver.find_element(:xpath, "(//input[@name='furigana'])[4]").send_keys "こまの つとむ"
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "(//select[@name='attr_4'])[4]")).select_by(:text, "D級")
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "(//select[@name='attr_3'])[4]")).select_by(:text, "2年")
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "(//select[@name='attr_3'])[4]")).select_by(:text, "3年")
    @driver.find_element(:xpath, "(//input[@name='name'])[5]").send_keys "大江 奏"
    @driver.find_element(:xpath, "(//input[@name='furigana'])[5]").send_keys "おおえ かなで"
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "(//select[@name='attr_2'])[5]")).select_by(:text, "女")
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "(//select[@name='attr_3'])[5]")).select_by(:text, "3年")
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "(//select[@name='attr_4'])[5]")).select_by(:text, "C級")
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "(//select[@name='attr_5'])[5]")).select_by(:text, "1")
    @driver.find_element(:xpath, "(//input[@name='name'])[6]").send_keys "筑波 秋博"
    @driver.find_element(:xpath, "(//input[@name='furigana'])[6]").send_keys "つくば あきひろ"
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "(//select[@name='attr_4'])[6]")).select_by(:text, "D級")
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "(//select[@name='attr_6'])[6]")).select_by(:text, "×")
    @driver.find_element(:xpath, "(//input[@name='name'])[7]").send_keys "花野 菫"
    @driver.find_element(:xpath, "(//input[@name='furigana'])[7]").send_keys "はなの すみれ"
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "(//select[@name='attr_2'])[7]")).select_by(:text, "女")
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "(//select[@name='attr_4'])[7]")).select_by(:text, "C級")
    Selenium::WebDriver::Support::Select.new(@driver.find_element(:xpath, "(//select[@name='attr_5'])[7]")).select_by(:text, "1")
    @driver.find_element(:id, "apply-add").click
    expect(element_present?(:xpath, "//div[@class='cb-container']/div[text()='追加完了']")).to be(true)
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
