ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  # Add more helper methods to be used by all tests here...
end

class ActionDispatch::IntegrationTest
  # A real user (the users.yml fixtures have no usable password), signed in
  # (short email domain: User caps emails at 20 characters)
  def sign_in_new_user(name: "tankowner", email: "#{name}@ex.com", **preferences)
    user = User.create!(name:, email:, password: "secret123", **preferences)
    post login_url, params: { email: user.email, password: "secret123" }
    user
  end
end
