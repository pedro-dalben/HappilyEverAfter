if User.count.zero?
  User.create!(
    email: "admin@example.com",
    password: "password123",
    password_confirmation: "password123"
  )
  puts "Created initial admin user: admin@example.com / password123"
end
