# Require the dependencies file to load the vendor libraries
require File.expand_path(File.join(File.dirname(__FILE__), 'dependencies'))

class MsprojectProjectTaskCreateV1
  def initialize(input)
    # Set the input document attribute
    @input_document = REXML::Document.new(input)

    # Store the info values in a Hash of info names to values.
    @info_values = {}
    REXML::XPath.each(@input_document,"/handler/infos/info") { |item|
      @info_values[item.attributes['name']] = item.text
    }
    @enable_debug_logging = @info_values['enable_debug_logging'] == 'Yes'

    # Store parameters values in a Hash of parameter names to values.
    @parameters = {}
    REXML::XPath.match(@input_document, '/handler/parameters/parameter').each do |node|
      @parameters[node.attribute('name').value] = node.text.to_s
    end
  end

  def execute()
    resources_path = File.join(File.expand_path(File.dirname(__FILE__)), 'resources')

    # Create the command string that will be used to retrieve the cookies
    cmd_string = "O365Auth.Console.exe #{@info_values['ms_project_location']} #{@info_values['username']} #{@info_values['password']} #{@info_values['integrated_authentication']}"

    # Retrieve the cookies
    cookies = `cd "#{resources_path}" & #{cmd_string}`

    proj_resource = RestClient::Resource.new(@info_values['ms_project_location'],
    :headers => {:content_type => "application/json",:accept => "application/json", :cookie => cookies})

    set_form_digest(proj_resource)

    project_id = @parameters['project_id']
    taskName = @parameters['name']
    taskNotes = @parameters['notes']
    
    update_params = {"name" => taskName}
    update_params["notes"] = taskNotes if taskNotes != ""

    task_endpoint = proj_resource["/_api/ProjectServer/Projects('#{project_id}')/Draft/Tasks"]

    puts "Creating a Task for the Project '#{project_id}" if @enable_debug_logging
    begin
      results = task_endpoint.post update_params.to_json
    rescue RestClient::Exception => error
      raise StandardError, error.inspect
    end

    puts "Parsing the result to get the task id" if @enable_debug_logging
    json = JSON.parse(results)

    puts json.inspect
    # Get the JSON value array that contains the lookup table information
    task_id = json["id"]

    puts "Returning results" if @enable_debug_logging
    <<-RESULTS
    <results>
      <result name="task_id">#{task_id}</result>
    </results>
    RESULTS
  end

  def set_form_digest(proj_resource)
    context_endpoint = proj_resource["/_api/contextinfo"]
    puts "Sending a request to get the FormDigestValue that will be passed at the X-RequestDigest header in the create call"
    begin
      results = context_endpoint.post ""
    rescue RestClient::Exception => error
      raise StandardError, error.inspect
    end

    json = JSON.parse(results)
    # Get the JSON value array that contains the lookup table information
    form_digest_value = json["FormDigestValue"]
    puts "Retrieved Form Digest: #{form_digest_value}"
    proj_resource.headers["X-RequestDigest"] = form_digest_value
end

  # This is a template method that is used to escape results values (returned in
  # execute) that would cause the XML to be invalid.  This method is not
  # necessary if values do not contain character that have special meaning in
  # XML (&, ", <, and >), however it is a good practice to use it for all return
  # variable results in case the value could include one of those characters in
  # the future.  This method can be copied and reused between handlers.
  def escape(string)
    # Globally replace characters based on the ESCAPE_CHARACTERS constant
    string.to_s.gsub(/[&"><]/) { |special| ESCAPE_CHARACTERS[special] } if string
  end
  # This is a ruby constant that is used by the escape method
  ESCAPE_CHARACTERS = {'&'=>'&amp;', '>'=>'&gt;', '<'=>'&lt;', '"' => '&quot;'}
end