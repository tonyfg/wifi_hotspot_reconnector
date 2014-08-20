require 'selenium-webdriver'


@@creds =
[
 [ 'login1', 'pass1' ],
 [ 'login2', 'pass2' ]
]


fork do
  exec 'phantomjs --webdriver=9876'
end
sleep 1
@@driver = Selenium::WebDriver.for(:remote, :url => "http://localhost:9876")


def connected?
  puts 'Checking connection...'
  val = system('ping -c2 google.com')

  if val
    puts 'Connection is OK.'
  else
    puts 'Connection is down...'
  end

  val
end


def reconnect_wifi
  puts 'Resetting wifi card and connection...'
  `rmmod wl`
  `modprobe wl`
  `iw wlan0 set power_save off`
  `iw wlan0 set txpower fixed 199715979263`
  sleep 1
  `nmcli con up id fozcoa-digital`
  sleep 1
  puts 'Wifi card reset!'
end


def reauth_hotspot
  puts 'Reauthenticating with hotspot...'
  connection_ok = false
  @@driver.navigate.to "http://fozcoadigital.info/login"

  @@creds.each do |(login, pass)|
    form = @@driver.find_element(:name, 'login')

    loginfield = form.find_element(:name, 'username')
    loginfield.click
    loginfield.send_keys login

    passfield = form.find_element(:name, 'password')
    passfield.click
    passfield.send_keys pass

    accept_conditions = form.find_element(:name, 'check')
    accept_conditions.click

    form.submit

    if connected?
      connection_ok = true
      break
    end

    puts 'Ended reauth try without success...'
  end

  if connection_ok
    puts 'Authenticated and internet connection is active!!!'
  else
    puts 'Could not reauthenticate after all possible credentials were tried... Trying again in a bit'
  end
end


loop do
  begin
    unless connected?
      reconnect_wifi
      reauth_hotspot
    end
  rescue
    puts 'Unknown error. Retrying in 10s...'
  end

  sleep 15
end
