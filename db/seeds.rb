# Test expects an empty database
return if Rails.env.test?

User.find_or_create_by!(name: "publisher")
