# USAGE
# $ bundle exec tux
# >> load 'scripts/tux_login.rb'

user_id = 73 # change this to whatever id you want to log in

msg = SecureRandom.base64(12)
user = User[user_id]
hash = Kagetra::Utils.hmac_password(user.password_hash,msg)
req = request '/api/user/auth/user', method: 'POST', input: "user_id=#{user_id}&hash=#{hash}&msg=#{msg}"
p req.body
