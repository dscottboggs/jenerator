require "compiler/crystal/formatter"
require "json"

class Jenerator
  @result : String::Builder
  @type_is_class : Bool

  def initialize(@type_is_class = true)
    @result = String::Builder.new
    @result << %[require "json"\n\n]
  end

  def self.process(data : IO | String, document_name = "document", type_is_class = true) : String
    code = new(type_is_class).parse(data, document_name).to_s
    begin
      Crystal::Formatter.format code
    rescue e : Crystal::SyntaxException
      STDERR.puts "WARNING: invalid Crystal syntax encountered at line #{e.line_number} character #{e.column_number}: #{e.message}"
      code
    end
  end

  def parse(data received : IO | String, document_name = "document") : self
    data = JSON.parse received
    class_or_struct document_name do
      parse_mapping data.as_h # Must be a top-level mapping
    end
    self
  end

  def class?
    @type_is_class
  end

  private def parse_mapping(data)
    parse_mapping(data) { }
  end

  private def parse_mapping(data)
    data.each do |key, value|
      key, ann = sanitize_key key
      if mapping = value.as_h?
        class_or_struct key do
          parse_mapping mapping
        end
        @result << ann <<                # in case of JSON key that can't be used as a Crystal name
          '@' << key <<                  # name of the variable
          " : " << key.camelcase << '\n' # Type of the variable
        yield key, key.camelcase
      elsif array = value.as_a?
        types = parse_array array, key
        @result << ann <<        # in case of JSON key that can't be used as a Crystal name
          '@' << key <<          # name of the variable
          " : " << types << '\n' # Type of the variable
        yield key, types
      else
        # append scalar ivar
        type = type_of_scalar value
        @result << ann <<       # in case of JSON key that can't be used as a Crystal name
          '@' << key <<         # name of the variable
          " : " << type << '\n' # Type of the variable
        yield key, type
      end
    end
  end

  private def parse_array(data, key)
    counter = 1
    types = Hash(String, Set(Tuple(String, String))).new do
      Set(Tuple(String, String)).new
    end
    data.each do |value|
      if mapping = value.as_h?
        class_name = "#{key.lstrip('_').camelcase}ArrayMember#{counter}"
        class_or_struct class_name do
          parse_mapping mapping do |name, type|
            types[class_name] = types[class_name].add({name, type.to_s})
          end
        end
        counter += 1
      elsif array = value.as_a?
        types["Array(#{parse_array(array, key + counter.to_s)})"] = Set(Tuple(String, String)).new
      else
        types[type_of_scalar(value).to_s] = Set(Tuple(String, String)).new
      end
    end
    tnames = Set(String).new
    types.each do |name, ivars|
      if ivars.empty? # Scalar or array type
        tnames.add name
        next
      end
      next if tnames.any? { |it| types[it] == ivars }
      tnames.add name
    end
    "Array(#{tnames.join(" | ")})"
  end

  private def sanitize_key(key)
    first = true
    sanitized = key.gsub do |char|
      char = char.downcase if first
      first = false
      next char if char.alphanumeric? || char == '_'
      '_'
    end
    sanitized = "_" if sanitized.empty?
    sanitized = '_' + sanitized if sanitized[0].number?
    sanitized = sanitized.underscore # Convert camelCase or PascalCase
    if sanitized == key
      {key, ""}
    else
      {sanitized, %{@[JSON::Field(key: "#{key}")]\n}}
    end
  end

  private def class_or_struct(name)
    @result << if class?
      "class "
    else
      "struct "
    end << name.camelcase << '\n' <<
      "include JSON::Serializable\n"
    yield
  ensure
    @result << "end\n"
  end

  private def type_of_scalar(data) : Class.class
    case data
    when .as_s? then String
    when .as_i? then Int64
    when .as_f? then Float64
    else
      return Bool unless data.as_bool?.nil?
      begin
        data.as_nil
        Nil
      rescue
        raise "Non-scalar type received for value #{data.raw}"
      end
    end
  end

  # Can only be called once!
  def to_s : String
    @result.to_s
  end
end
