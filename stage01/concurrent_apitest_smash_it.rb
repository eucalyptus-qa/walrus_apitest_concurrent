#!/usr/bin/ruby
# Author: Neil Soman <neil@eucalyptus.com>

require 'rubygems'
require 'right_aws'

def log_success(message)
#    puts "[TEST_REPORT]\t" + message
	File.open( "threads_output.txt", "a+" ) do |the_file| 
        	the_file.puts "[TEST_REPORT]\t" + message 
	end 
end

def log_failure(message)
#    puts "[TEST_REPORT]\tFAILED: " + message
	File.open( "threads_output.txt", "a+" ) do |the_file| 
#        	the_file.puts "[TEST_REPORT]\tFAILED: " + message 		### do not fail in "smash" mode
        	the_file.puts "[TEST_REPORT]\tWARNING: " + message 
	end
#    exit(1)
end

def generate_string( len )
    chars = ("a".."z").to_a + ("A".."Z").to_a + ("0".."9").to_a
    generate_string = ""
    1.upto(len) { |i| generate_string << chars[rand(chars.size-1)] }
    return generate_string
end

def make_bucket(connection, bucketname, create)
begin
    bucket = RightAws::S3::Bucket.create(connection, 'test_bucket_%s' % generate_string(10), create)
    log_success("Created Bucket: %s" % bucketname)
    return bucket
rescue RightAws::AwsError
    log_failure("Error in Creating Bucket %s" % bucketname)
end
end

def put_object(bucket, objectname)
    key = RightAws::S3::Key.create(bucket, objectname)
    key.data = 'werignrewngorwengiwrenginerwignioerwngirwengvndfrsignoreihgioerqngoirengoinianroignoignriaongr2202fg3q4gwng'
    key.put 
#    log_success("Adding object: %s" % objectname)
    return key
end

def get_object(bucket, objectname)
    key = RightAws::S3::Key.create(bucket, objectname)
    key.get
    log_success("Last Modified: %s" % key.last_modified + "Owner: %s" % key.owner + "Size: %s" % key.size)
end

def delete_object(key)
    if key.delete
#	log_success("Object %s deleted" % key.name)
    else
	log_failure("Unable to Delete Object %s" % key.name)
    end
end

def show_buckets(connection)
    my_buckets_names = connection.buckets.map{|b| b.name}
    puts my_buckets_names
end

def delete_bucket(bucket)
begin
    if bucket.delete(true)
        log_success("Bucket %s Deleted" % bucket.name)
    else
	log.success("Unable to Delete Bucket: %s" % bucket.name)
    end
rescue RightAws::AwsError
    log_failure("Error in Creating Bucket %s" % bucketname)
end
end

def setup_ec2
    return RightAws::Ec2.new(ENV['EC2_ACCESS_KEY'],ENV['EC2_SECRET_KEY'])
end

def setup_s3
    s3 = RightAws::S3.new(aws_access_key_id=ENV['EC2_ACCESS_KEY'], aws_secret_access_key=ENV['EC2_SECRET_KEY'], {:multi_thread => true})
end

def screen_dump(string)
    log_success("=================================== %s ===================================" % string)
end

def test0(s3, tid)
begin
    screen_dump('[THREAD_ID %d] Testing Get Object by Prefix' % tid)
    num_keys = 50
    bucketname = 'test_bucket_%s' % generate_string(10)
    bucket = RightAws::S3::Bucket.create(s3, bucketname, true, 'public-read', :location => :us)
    log_success("[THREAD_ID %d] Created Bucket: %s" % [tid, bucketname])
    log_success("[THREAD_ID %d] Number of Objects to be Inserted: %d" % [tid, num_keys])
    log_success("[THREAD_ID %d] Inserting Objects into the Bucket" )
    objects = Array.new
    num_keys.times {  object = put_object(bucket, 'test_object_%s' % generate_string(10))
		objects << object
	     }
    keys = bucket.keys('prefix' => 'test_')
    log_success("[THREAD_ID %d] Number of Objects Returned with Prefix 'test_': %d" % [tid, keys.size])
    if keys.size != num_keys 
	log_failure("[THREAD_ID %d] test0 failed. Prefix did not return correct number of keys." % tid)
    end
    keys = bucket.keys('prefix' => 'test11')
    if keys.size > 0
	log_failure("[THREAD_ID %d] test0 failed. Invalid return on prefix." %tid)
    end
    log_success("[THREAD_ID %d] Deleting Objects from the Bucket" )
    objects.each do |object|
	delete_object(object)
    end
    log_success("[THREAD_ID %d] Deleting the Bucket: %s" % [tid, bucketname])
    delete_bucket(bucket)
rescue RightAws::AwsError
    log_failure("[THREAD_ID %d] test0 failed" % tid)
end
    screen_dump('[THREAD_ID %d] End of Testing Get Object by Prefix' % tid)
end

def test1(s3, tid)
begin
    num_keys = 25 
    max_keys = 17
    screen_dump('[THREAD_ID %d] Testing Get Max Keys' % tid)
    bucketname = 'test_bucket_%s' % generate_string(10)
    bucket = RightAws::S3::Bucket.create(s3, bucketname, true, 'public-read', :location => :us)
    log_success("[THREAD_ID %d] Created Bucket: %s" % [tid, bucketname])
    log_success("[THREAD_ID %d] Number of Objects to be Inserted: %d" % [tid, num_keys])
    log_success("[THREAD_ID %d] Max Keys: %d" % [tid, max_keys])
    log_success("[THREAD_ID %d] Inserting Objects into the Bucket" )
    objects = Array.new
    num_keys.times {  object = put_object(bucket, 'test_object_%s' % generate_string(10))
		objects << object
	     }
    keys = bucket.keys('max-keys' => max_keys)
    log_success("[THREAD_ID %d] Number of Objected Returned: %d" % [tid, keys.size])
    if keys.size != max_keys 
	log_failure("[THREAD_ID %d] test1 failed. max-keys did not return correct number of keys." % tid)
    end
    log_success("[THREAD_ID %d] Deleting Objects from the Bucket" )
    objects.each do |object|
	delete_object(object)
    end
    log_success("[THREAD_ID %d] Deleting the Bucket: %s" % [tid, bucketname])
    delete_bucket(bucket)
rescue RightAws::AwsError
    log_failure("[THREAD_ID %d] test1 failed" % tid)
end
    screen_dump('[THREAD_ID %d] End of Testing Get Max Keys' % tid)
end

def test2(s3, tid)
begin
    num_keys = 10
    screen_dump('[THREAD_ID %d] Testing Get Object by Marker' %tid)
    bucketname = 'test_bucket_%s' % generate_string(10)
    bucket = RightAws::S3::Bucket.create(s3, bucketname, true, 'public-read', :location => :us)
    log_success("[THREAD_ID %d] Created Bucket: %s" % [tid, bucketname])
    log_success("[THREAD_ID %d] Number of Objects to be Inserted: %d" % [tid, num_keys])
    log_success("[THREAD_ID %d] Inserting Objects into the Bucket" )
    objects = Array.new
    num_keys.times {  object = put_object(bucket, 'test_object_%s' % generate_string(10))
		objects << object
	     }
    keys = bucket.keys('marker' => 't')
    log_success("[THREAD_ID %d] Number of Objects Returned using Marker 't': %d" % [tid, keys.size])
    if keys.size != num_keys 
	log_failure("[THREAD_ID %d] test2 failed. Marker did not return correct number of keys." % tid)
    end
    keys = bucket.keys('marker' => 'z')
    if keys.size > 0
	log_failure("[THREAD_ID %d] test2 failed. Invalid return on marker." % tid)
    end
    log_success("[THREAD_ID %d] Deleting Objects from the Bucket" )
    objects.each do |object|
	delete_object(object)
    end
    log_success("[THREAD_ID %d] Deleting the Bucket: %s" % [tid, bucketname])
    delete_bucket(bucket)
rescue RightAws::AwsError
    log_failure("[THREAD_ID %d] test2 failed" % tid)
    screen_dump('[THREAD_ID %d] Testing Get Object by Marker' % tid)
end
end

def test3(s3, tid)
begin
    screen_dump('[THREAD_ID %d] Testing Get Object By Delimiter' % tid)
    bucketname = 'test_bucket_%s' % generate_string(10)
    bucket = RightAws::S3::Bucket.create(s3, bucketname, true, 'public-read', :location => :us)
    log_success("[THREAD_ID %d] Created Bucket: %s" % [tid, bucketname])
    log_success("[THREAD_ID %d] Inserting Objects into the Bucket" )
    object1 = put_object(bucket, 'mydir-help-man1')
    object2 = put_object(bucket, 'mydir-help-man2')
    object3 = put_object(bucket, 'mydir-help-man3')
    object4 = put_object(bucket, 'mydir-test1')
    keys = bucket.keys('prefix' => 'mydir-', 'delimiter' => '-')
    log_success("[THREAD_ID %d] Number of Objects Returned using Delimiter: %d" % [tid, keys.size])
    if keys.size != 1
 	log_failure("[THREAD_ID %d] test3 failed. wrong number of keys returned." % tid)
    end
    log_success("[THREAD_ID %d] Deleting Objects from the Bucket" )
    delete_object(object1)
    delete_object(object2)
    delete_object(object3)
    delete_object(object4)
    log_success("[THREAD_ID %d] Deleting the Bucket: %s" % [tid, bucketname])
    delete_bucket(bucket)
rescue RightAws::AwsError
    log_failure("[THREAD_ID %d] test3 failed" % tid)
end
    screen_dump('[THREAD_ID %d] End of Testing Get Object By Delimiter' % tid)
end

system("rm -f threads_output.txt");

s3 = setup_s3

threads = []

for i in (1..10)
  threads << Thread.new(i) { 
	my_thread_id = Thread.current.object_id
	test0(s3, my_thread_id)
	test1(s3, my_thread_id)
	test2(s3, my_thread_id)
	test3(s3, my_thread_id)
  }
end

threads.each { |thread|  
	my_id = thread.object_id
	puts ""
	puts "THIS THREAD ID: %d" % my_id
	puts ""
	system("cat threads_output.txt | grep %d" % my_id);
#	puts thread
	thread.join
	puts ""
	puts "TERMINATED THREAD ID: %d" % my_id
	puts ""
}

system("rm -f threads_output.txt");

