require "rubygems"
require "open-uri"
require "nokogiri"
require "zip"
require "redis"

redis = Redis.new

def download_zip(url,zip_name,redis)
	uri_zip = URI.parse(url)
	result = Net::HTTP.get_response(uri_zip)

	#Write zip file to local zip file under same name as original
	new_zip = open(zip_name, "w")
	new_zip.write(result.body)
	new_zip.close

	Zip::File.open(new_zip.path) do |zip_file|  
  		zip_file.each do |entry|   	
    		#Checks if xml file has already been entered before adding content to redis list
    		if redis.get(entry).nil?
    			redis.set(entry,"content exists")
	    		puts "Extracting... #{entry}"
	    		content = zip_file.read(entry)
	    		redis.lpush("NEWS_XML",content)
	    	end
  		end
	end	
end

def locate_zip(redis)
	#parse site for a tags
	page = Nokogiri::HTML(open("http://feed.omgili.com/5Rh5AMTrc4Pv/mainstream/posts/"))
	urls = page.css("a")
	#for each a tag parse zip file link
	urls.each do |url|
		zip_link = url["href"]
		#Ensures only zip files that have not yet been downloaded are downloaded and pushed to redis list
		if !File.exist?(zip_link) && zip_link.include?(".zip")
			zip_to_download = "http://feed.omgili.com/5Rh5AMTrc4Pv/mainstream/posts/" + zip_link
			download_zip(zip_to_download,zip_link,redis)
		end
	end
end

locate_zip(redis)


