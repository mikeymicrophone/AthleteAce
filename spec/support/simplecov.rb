require 'simplecov'

SimpleCov.start 'rails' do
  skip '/bin/'
  skip '/db/'
  skip '/spec/'
  skip '/config/'
  skip '/vendor/'
  skip '/lib/tasks/'
  
  group 'Controllers', 'app/controllers'
  group 'Models', 'app/models'
  group 'Helpers', 'app/helpers'
  group 'Views', 'app/views'
  group 'Mailers', 'app/mailers'
  group 'Jobs', 'app/jobs'
end
