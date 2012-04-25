#!/usr/bin/ruby
# Author: Neil Soman <neil@eucalyptus.com>

require 'rubygems'
require 'right_aws'

def log_success(message)
    puts "[TEST_REPORT]\t" + message
end

def log_failure(message)
    puts "[TEST_REPORT]\tFAILED: " + message
    exit(1)
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
    log_success("Created bucket: %s" % bucketname)
    return bucket
rescue RightAws::AwsError
    log_failure("Error creating bucket %s" % bucketname)
end
end

def put_object(bucket, objectname)
    key = RightAws::S3::Key.create(bucket, objectname)
    key.data = 'werignrewngorwengiwrenginerwignioerwngirwengvndfrsignoreihgioerqngoirengoinianroignoignriaongr2202fg3q4gwng'
    key.put 
    log_success("Adding object: %s" % objectname)
    return key
end

def get_object(bucket, objectname)
    key = RightAws::S3::Key.create(bucket, objectname)
    key.get
    log_success("Last Modified: %s" % key.last_modified + "Owner: %s" % key.owner + "Size: %s" % key.size)
end

def delete_object(key)
    if key.delete
	log_success("Object %s deleted" % key.name)
    else
	log_failure("Unable to delete object %s" % key.name)
    end
end

def show_buckets(connection)
    my_buckets_names = connection.buckets.map{|b| b.name}
    puts my_buckets_names
end

def delete_bucket(bucket)
begin
    if bucket.delete(true)
        log_success("Bucket %s deleted" % bucket.name)
    else
	log.success("Unable to delete bucket: %s" % bucket.name)
    end
rescue RightAws::AwsError
    log_failure("Error creating bucket %s" % bucketname)
end
end

def setup_ec2
    return RightAws::Ec2.new(ENV['EC2_ACCESS_KEY'],ENV['EC2_SECRET_KEY'])
end

def setup_s3
    s3 = RightAws::S3.new(aws_access_key_id=ENV['EC2_ACCESS_KEY'], aws_secret_access_key=ENV['EC2_SECRET_KEY'], {:multi_thread => true})
end

def screen_dump(string)
    log_success("******%s******" % string)
end

def test0(s3)
begin
    num_keys = 50
    screen_dump('Object Prefix')
    bucketname = 'test_bucket_%s' % generate_string(10)
    bucket = RightAws::S3::Bucket.create(s3, bucketname, true, 'public-read', :location => :us)
    log_success("Created bucket: %s" % bucketname)
    objects = Array.new
    num_keys.times {  object = put_object(bucket, 'test_object_%s' % generate_string(10))
		objects << object
	     }
    keys = bucket.keys('prefix' => 'test_')
    if keys.size != num_keys 
	log_failure("test0 failed. Prefix did not return correct number of keys.")
    end
    keys = bucket.keys('prefix' => 'test11')
    if keys.size > 0
	log_failure("test0 failed. Invalid return on prefix.")
    end
    objects.each do |object|
	delete_object(object)
    end
    delete_bucket(bucket)
rescue RightAws::AwsError
    log_failure("test0 failed")
end
end

def test1(s3)
begin
    num_keys = 25 
    max_keys = 17
    screen_dump('Max Keys')
    bucketname = 'test_bucket_%s' % generate_string(10)
    bucket = RightAws::S3::Bucket.create(s3, bucketname, true, 'public-read', :location => :us)
    log_success("Created bucket: %s" % bucketname)
    objects = Array.new
    num_keys.times {  object = put_object(bucket, 'test_object_%s' % generate_string(10))
		objects << object
	     }
    keys = bucket.keys('max-keys' => max_keys)
    if keys.size != max_keys 
	log_failure("test1 failed. max-keys did not return correct number of keys.")
    end
    objects.each do |object|
	delete_object(object)
    end
    delete_bucket(bucket)
rescue RightAws::AwsError
    log_failure("test1 failed")
end
end

def test2(s3)
begin
    num_keys = 10
    screen_dump('Object Marker')
    bucketname = 'test_bucket_%s' % generate_string(10)
    bucket = RightAws::S3::Bucket.create(s3, bucketname, true, 'public-read', :location => :us)
    log_success("Created bucket: %s" % bucketname)
    objects = Array.new
    num_keys.times {  object = put_object(bucket, 'test_object_%s' % generate_string(10))
		objects << object
	     }
    keys = bucket.keys('marker' => 't')
    if keys.size != num_keys 
	log_failure("test2 failed. Marker did not return correct number of keys.")
    end
    keys = bucket.keys('marker' => 'z')
    if keys.size > 0
	log_failure("test2 failed. Invalid return on marker.")
    end
    objects.each do |object|
	delete_object(object)
    end
    delete_bucket(bucket)
rescue RightAws::AwsError
    log_failure("test2 failed")
end
end

def test3(s3)
begin
    screen_dump('Object Delimiter')
    bucketname = 'test_bucket_%s' % generate_string(10)
    bucket = RightAws::S3::Bucket.create(s3, bucketname, true, 'public-read', :location => :us)
    log_success("Created bucket: %s" % bucketname)
    object1 = put_object(bucket, 'mydir-help-man1')
    object2 = put_object(bucket, 'mydir-help-man2')
    object3 = put_object(bucket, 'mydir-help-man3')
    object4 = put_object(bucket, 'mydir-test1')
    keys = bucket.keys('prefix' => 'mydir-', 'delimiter' => '-')
    if keys.size != 1
 	log_failure("test3 failed. wrong number of keys returned.")
    end
    delete_object(object1)
    delete_object(object2)
    delete_object(object3)
    delete_object(object4)
    delete_bucket(bucket)
rescue RightAws::AwsError
    log_failure("test3 failed")
end
end

s3 = setup_s3

threads = []

for i in (1..10)
  threads << Thread.new(i) { 
	test0(s3)
	test1(s3)
	test2(s3)
	test3(s3)
  }
end

threads.each { |thread|  puts thread; thread.join }

