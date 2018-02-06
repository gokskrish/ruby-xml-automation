
require 'rubygems'
require 'net/http'
require 'aws/s3'

(application_url, secret_key, update_zip_file_name) = ARGV
#puts application_url
#puts update_zip_file_name

unless application_url && secret_key && update_zip_file_name
  puts "Usage: upload_book.rb <APPLICATION_URL> <OUR_SECRET_KEY> <UPDATE_ZIP_FILE>"
  puts "For example: ruby upload_update.rb books-iphone.medhand.com <OUR_SECRET_KEY> path/to/your/com.medhand.books.test_revision_99_99_update.zip"
  exit -1
end

begin
  book_id = update_zip_file_name.split('_update.zip').first.split("/").last
  #puts book_id

  uri = URI("http://#{application_url}/books/book_path?bookID=#{book_id}")
  response = Net::HTTP.get_response(uri)
  #puts response.message
  #puts response.body
rescue
  puts 'Could not retrieve the book path on amazon s3'
  puts 'The heroku server could not be contacted'
  exit -2
end

unless (response.message.start_with?('OK'))
  puts 'Could not retrieve the book path on amazon s3'
  puts 'The heroku server did not respond or responded with an error'
  exit -3
end

unless (!response.body.empty?)
  puts 'Could not retrieve the book path on amazon s3'
  puts 'The book does not seem to exist on the heroku server'
  exit -4
end

rsp = response.body.split(":")
unless rsp.count == 3
  puts 'Could not retrieve the book path on amazon s3'
  puts 'Response not recognised'
  exit -5
end

begin
  bucket_name = rsp[0]
  update_zip = rsp[2]
  #puts bucket_name
  #puts update_zip

  AWS::S3::Base.establish_connection!(:access_key_id => 'AKIAIUG6G55VVOKQPVLQ', :secret_access_key => secret_key)
  AWS::S3::S3Object.store(update_zip, open(update_zip_file_name), bucket_name)
rescue
  puts 'Could not upload to amazon s3'
  exit -6
end

puts "Uploaded #{update_zip_file_name} to: #{update_zip}"
