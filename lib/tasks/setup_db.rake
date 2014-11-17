require 'json'

task :setup_db => [
  :create_categories,
  :load_data
  ]

task :load_data => :environment do
  # file = 'data/sample_data.json'
  file = 'data/data_2.json'

  puts "===> Populating the #{Rails.env} DB with #{file}..."
  puts '===> Depending on the size of your data, this can take several minutes...'

  Organization.destroy_all
  File.open(file).each do |line|
    data_item = JSON.parse(line)
    begin
      org = Organization.create!(data_item.except('locations'))
    rescue Exception => e
      # What if the org is already created? Find it.
      if e.message == "Validation failed: Name has already been taken"
        org = Organization.where(name: data_item.except('locations')['name'] ).first
      end
    end

    binding.pry unless org

    locs = data_item['locations']
    binding.pry unless locs
    locs.each do |location|
      location = org.locations.new(location)
      unless location.save
        name = location['name']
        invalid_records = {}
        invalid_records[name] = {}
        invalid_records[name]['errors'] = location.errors
        File.open('data/invalid_records.json','a') do |f|
          f.puts(invalid_records.to_json)
        end
      end
      # If you get Geocoder::OverQueryLimitError when running this rake task,
      # uncomment line 34 and play with different sleep values, or use a
      # different geocoding service. See the Wiki for more details:
      # https://github.com/codeforamerica/ohana-api/wiki#customization
      # sleep 0.2
    end
  end
  puts "===> Done populating the DB with #{file}."
  if File.exists?('data/invalid_records.json')
    puts '===> Some locations failed to load. Check data/invalid_records.json.'
  end
end