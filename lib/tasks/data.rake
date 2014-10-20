namespace :data do
  desc "Import first batch"
  task :import_1 => [:environment] do

    require 'street_address'
    require 'pry'
    require 'json'

    # Read the csv file
    file = CSV.read(Rails.root.join("data/data.csv"),{headers: true})

    # Make sure the output file exists
    FileUtils.touch(Rails.root.join("data/data_2.json"))
    # Truncate the output file
    File.truncate(Rails.root.join("data/data_2.json"),0)
    # Open the output file
    File.open(Rails.root.join("data/data_2.json"), "a") do |output|

      #
      # ORGANIZATION
      #

      # Create a hash for every "organization" in the cursor
      # Assign row's the value of "organization" as "name" field in org hash
      organizations = file["organization"].uniq.map{|name| {name: name} }.compact

      #
      # For every organization...
      #

      # Insert "urls" field at "urls" field of "organization"
      organizations.each.with_index do |org,i|
        cursor = file.find{|row|row["organization"] == org[:name]}
        if cursor["urls"]
          urls = cursor["urls"]

          # Normalize urls
          if !urls.starts_with?("http")
            urls = "http://#{urls}"
          end
          organizations[i][:urls] = [urls]
        end

        # puts "===> Organization: #{org[:name]}"
        # Why don't some orga have names? Just ignoring them.
        next unless org[:name]

        #
        # LOCATION
        #
        # Create a location hash for every semi-colon separated entity in "facilities" field of a service.
        facilities = cursor["facilities"].try(:split,";").try(:map, &:strip)

        # If the field is blank, assign the name of the organization
        if facilities.blank?
          facilities = [org[:name]]
        end

        # Assign row's facilities array to the "locations" field of the organization.
        organizations[i][:locations] = facilities

        #
        # For every location...
        #
        organizations[i][:locations].each.with_index do |loc,j|

          unless loc.present?
            loc = 'Service Location Name'
          end
          location = {name: loc}
          # Assign row's "description" to "description"
          location[:description] = cursor["description"] || loc
          # Assign row's "languages" to location's "languages" field.
          location[:languages] = cursor["languages"]
          # Assign cursor's "hours_available" to "hours"
          location[:hours] = cursor["hours_available"]
          # Assign cursor's "phones" to "phones"
          location[:phones_attributes] = cursor["phones"].split(';').map{|item|{number: item}} if cursor["phones"]

          #
          # ADDRESS
          #

          # Create an address hash if there is an address
          # address_value = organizations[i][:locations][j]

          # if _address = StreetAddress::US.parse(address_value)
          #   # Parse the row's "facilities" field's value
          #   address = {street: _address.street || "NO ADDRESS PROVIDED" , city: _address.city || "NYC", state: _address.state || "NY", zip: _address.try(:zip) || "11102"}
          #   # Assign address hash to the location's "address_attributes" field.
          #   location[:address_attributes] = address.compact
          # else
          #   location[:address_attributes] = {street: "NO ADDRESS PROVIDED", zip: "11102", state: "NY", city: "NYC"}
          # end

          #
          # CONTACTS
          #

          # For every email in row's "emails", create a contact hash
          if cursor["emails"]
            emails = cursor["emails"]
            # Remove ",or "
            emails.gsub(", or ", ",")
            emails = emails.split(",")
            emails = emails.map{|em| em.split(";")}
            emails = emails.flatten
            emails.each do |email|
              email.strip!

              # Why doesnt this work for this one email address?
              if email == 'jbreen@cfthomeless.org '
                email = email[0..emails.length-3]
              end

              # Remove the last period
              email.gsub!('\.$','')


              contact = {email: email}
              # For every name in row's "staff_contacts", assign value to "name" in contact.

              # Name cannot be blank
              contact[:name]  = cursor["staff_contacts"] || "Staff member"
              # Title cannot be blank
              contact[:title] = "Staff member"

              # Insert contact to "contacts_attributes" array of location
              location[:contacts_attributes] ||= []
              location[:contacts_attributes] << contact.compact
            end
          end


          #
          # For every service...
          #

          #
          # SERVICES
          #
          services = file["name"].uniq.map{|name| name }
          services.each do |_sname|
            # Create a service cursor
            _s = file.find{|row| row["organization"] == org[:name]  && row["name"] == _sname }
            if _s
              binding.pry unless _s["name"] or _sname
              # Create a service hash
              # Assign row's "name" field to service's "name" field
              service = {name: _s["name"] || _sname}
              # Assign row's "eligibility" to "eligibility"
              service[:eligibility] = _s["eligibility"]
              # Assign row's "description" to "description"
              service[:description] = _s["description"] || _s["name"]
              # Assign row's "how_to_access" to "how_to_apply"
              service[:how_to_apply] = _s["how_to_access"]
              # Assign row's "wait" to "wait"
              service[:wait] = _s["wait"]
              # Assign row's "method_of_payment" to "method_of_payment"
              service[:method_of_payment] = _s["method_of_payment"]
              # Assign row's "fees" to "fees"
              service[:fees] = _s["fees"]
              # Assign row's "short_desc" to "short_desc"
              service[:short_desc] = _s["short_desc"]
              # Create an array at "funding_sources" field
              # Insert "funding_sources" at "funding_sources" field
              service[:funding_sources] = [_s["funding_sources"]] if _s["funding_sources"]
              # Create an array at "service_areas" field
              # Insert "service_area" at "service_areas"
              service[:service_areas] = _s["service_area"].split(',') if _s["service_area"]

              # Insert service hash in an array at "services_attributes" field of the location.
              location[:services_attributes] ||= []
              location[:services_attributes] << service.compact
            end
          end


          # Reassign location to organization

          organizations[i][:locations][j] = location.compact
          # puts "    ===> Location: #{location[:name]}"

        end



        # Append the organization to output file
        output.write organizations[i].to_json
        # Append a line break
        output.write "\n"

      end
    end

  end
end