module YAML
	class << self
		alias_method :load, :unsafe_load if YAML.respond_to? :unsafe_load
		alias_method :original_dump, :dump
		alias_method :original_load_file, :load_file
	end

	def self.LOG(info)
		puts Time.new.strftime("%Y-%m-%d %H:%M:%S") + " [Info] " + "#{info}"
	end

	def self.LOG_ERROR(info)
		puts Time.new.strftime("%Y-%m-%d %H:%M:%S") + " [Error] " + "#{info}"
	end

	def self.LOG_WARN(info)
		puts Time.new.strftime("%Y-%m-%d %H:%M:%S") + " [Warning] " + "#{info}"
	end

	def self.LOG_TIP(info)
		puts Time.new.strftime("%Y-%m-%d %H:%M:%S") + " [Tip] " + "#{info}"
	end

	def self.load_file(filename, *args, **kwargs)
		yaml_content = File.read(filename)
		processed_content = fix_short_id_quotes(yaml_content)

		load(processed_content, *args, **kwargs)
	end

	def self.dump(obj, io = nil, **options)
		begin
			yaml_content = original_dump(obj, **options)
			processed = fix_short_id_quotes(yaml_content)
			if io.nil?
				processed
			elsif io.respond_to?(:write)
				io.write(processed)
				io
			else
				processed
			end
		rescue => e
			LOG_ERROR("Write file failed:【%s】" % [e.message])
			nil
		end
	end

	private

	# fix_short_id_quotes:
	# Purpose: ensure YAML `short-id` values are emitted with the intended
	# representation when dumping or re-writing YAML files.
	# Behavior:
	# - Non-null, non-empty scalar `short-id` values (and items inside
	#   `short-id` sequences) are written as double-quoted strings.
	# - Empty strings are preserved as empty quoted strings ("" remains "").
	# - Null values are preserved and may be emitted explicitly (e.g. `! "").
	# Lastly, use gsub to clean up any `! ""` tags
	# Examples:
	#   Input:  short-id: 00000000    -> Output: short-id: "00000000"
	#   Input:  short-id: ""          -> Output: short-id: ""
	#   Input:  short-id: "abc123"    -> Output: short-id: "abc123"
	#   Input:  short-id: "1600e237"  -> Output: short-id: "1600e237"
	#   Input:  short-id: null        -> Output: short-id: ""

	def self.fix_short_id_quotes(yaml_content)
		return yaml_content unless yaml_content.include?('short-id:')

		begin
			stream = Psych.parse_stream(yaml_content)

			traverse = lambda do |node|
				case node
				when Psych::Nodes::Mapping
					children = node.children || []
					i = 0
					while i < children.length
						key = children[i]
						val = children[i + 1]
						if key.is_a?(Psych::Nodes::Scalar) && key.value == 'short-id'
							if val.is_a?(Psych::Nodes::Scalar)
								is_null_scalar = (val.tag == 'tag:yaml.org,2002:null') || (val.tag == '!!null') || (val.value =~ /^\s*(~|null|NULL|Null)\s*$/)
								unless is_null_scalar
									val.tag = nil
									val.style = defined?(Psych::Nodes::Scalar::DOUBLE_QUOTED) ? Psych::Nodes::Scalar::DOUBLE_QUOTED : 2
								end
							elsif val.is_a?(Psych::Nodes::Sequence)
								val.children.each do |child|
									if child.is_a?(Psych::Nodes::Scalar)
										is_null_child = (child.tag == 'tag:yaml.org,2002:null') || (child.tag == '!!null') || (child.value =~ /^\s*(~|null|NULL|Null)\s*$/)
										unless is_null_child
											child.tag = nil
											child.style = defined?(Psych::Nodes::Scalar::DOUBLE_QUOTED) ? Psych::Nodes::Scalar::DOUBLE_QUOTED : 2
										end
									end
								end
							end
						else
							traverse.call(key) if key.respond_to?(:children)
							traverse.call(val) if val.respond_to?(:children)
						end
						i += 2
					end
				when Psych::Nodes::Sequence
					(node.children || []).each { |c| traverse.call(c) }
				when Psych::Nodes::Document, Psych::Nodes::Stream
					(node.children || []).each { |c| traverse.call(c) }
				else
					if node.respond_to?(:children)
						(node.children || []).each { |c| traverse.call(c) }
					end
				end
			end

			stream.children.each do |doc_node|
				if doc_node.is_a?(Psych::Nodes::Document)
					traverse.call(doc_node.root) if doc_node.root
				end
			end

			if stream.respond_to?(:to_yaml)
				processed_yaml = stream.to_yaml
				processed_yaml = processed_yaml.gsub(/^([ \t]*short-id:\s*)!\s*/, "\\1")
				processed_yaml
			else
				yaml_content
			end
		rescue => e
			LOG_ERROR("Fix short-id values type failed:【%s】" % [e.message])
			yaml_content
		end
	end

	def self.overwrite(base, override)
		return override if base.nil?
		return base if override.nil?

		current_key = nil
		current_operation = nil

		begin
			case override
			when Hash
				result = base.is_a?(Hash) ? base.dup : {}

				override.each do |key, value|
					current_key = key
					processed_key, operation = parse_key(key)
					current_operation = operation

					applied = apply_operation(result[processed_key], value, operation)
					if applied.equal?(DELETED_SENTINEL)
						result.delete(processed_key)
					else
						result[processed_key] = applied
					end
				end

				result
			else
				override
			end
		rescue => e
			LOG_ERROR("YAML overwrite failed:【key: %s, operation: %s, error: %s】" % [current_key, current_operation, e.message])
			base
		end
	end

	private

	def self.parse_key(key)
		key_str = key.to_s

		# +<key>
		if key_str.start_with?('+<') && key_str.include?('>')
			close_idx = key_str.index('>')
			inner_key = key_str[2...close_idx]
			return inner_key, :prepend_array
		end

		# <key>suffix
		if key_str.start_with?('<') && key_str.include?('>')
			close_idx = key_str.index('>')
			inner_key = key_str[1...close_idx]
			suffix = key_str[(close_idx + 1)..-1]
			return inner_key, determine_operation(suffix)
		end

		# 前缀 +key
		if key_str.start_with?('+')
			return key_str[1..-1], :prepend_array
		end

		# 尾部（支持 +, !, *, -）
		if key_str =~ /^(.*?)([+!*\-])$/
			return Regexp.last_match(1), determine_operation(Regexp.last_match(2))
		end

		[key_str, :merge]
	end

	def self.determine_operation(suffix)
		case suffix
		when '+'
			:append_array
		when '-'
			:delete
		when '!'
			:force_overwrite
		when '*'
			:batch_update
		else
			:merge
		end
	end

	def self.match_value(target, condition)
		return false if target.nil? || condition.nil?

		begin
			if condition.is_a?(String) && condition.start_with?('/') && condition.end_with?('/')
				pattern = condition[1...-1]
				regexp = Regexp.new(pattern)
				if target.is_a?(Array)
					target.any? { |item| item.to_s =~ regexp }
				else
					target.to_s =~ regexp
				end
			elsif condition.is_a?(Array) && target.is_a?(Array)
				condition.all? { |c| target.include?(c) }
			else
				target == condition
			end
		rescue => e
			LOG_ERROR("YAML overwrite failed:【(match value) => target: %s, condition: %s, error: %s】" % [target, condition, e.message])
			false
		end
	end

	def self.deep_dup(obj)
		case obj
		when Array
			obj.map { |x| deep_dup(x) }
		when Hash
			obj.transform_values { |v| deep_dup(v) }
		else
			obj.dup rescue obj
		end
	end

	def self.merge_hash(base, value, prepend: false)
		if prepend
			result = {}

			value.each do |k, v|
				if base.key?(k)
					result[k] = apply_operation(base[k], v, :merge)
				else
					result[k] = deep_dup(v)
				end
			end

			base.each do |k, v|
				result[k] = deep_dup(v) unless result.key?(k)
			end

			result
		else
			result = deep_dup(base)

			value.each do |k, v|
				if result.key?(k)
					result[k] = apply_operation(result[k], v, :merge)
				else
					result[k] = deep_dup(v)
				end
			end

			result
		end
	end

	def self.delete_from_hash(base, value)
		result = deep_dup(base)

		case value
		when Array
			value.each { |k| result.delete(k) }
		when Hash
			value.each do |k, v|
				if v.nil? || v == true
					result.delete(k)
				elsif result[k].is_a?(Hash) && v.is_a?(Hash)
					nested = apply_operation(result[k], v, :delete)
					if nested.equal?(DELETED_SENTINEL)
						result.delete(k)
					else
						result[k] = nested
					end
				else
					result.delete(k)
				end
			end
		else
			result.delete(value)
		end

		result
	end

	DELETED_SENTINEL = Object.new.freeze

	def self.apply_operation(base, value, operation)
		case operation
		when :delete
			if base.is_a?(Array) && value.is_a?(Array)
				base - value
			elsif base.is_a?(Array) && !value.nil?
				base - [value]
			elsif base.is_a?(Hash)
				delete_from_hash(base, value)
			else
				DELETED_SENTINEL
			end
		when :force_overwrite
			deep_dup(value)
		when :prepend_array
			if base.is_a?(Array) && value.is_a?(Array)
				(deep_dup(value) + base).uniq
			elsif base.is_a?(Hash) && value.is_a?(Hash)
				merge_hash(base, value, prepend: true)
			else
				deep_dup(value)
			end
		when :append_array
			if base.is_a?(Array) && value.is_a?(Array)
				base_dup = base.dup
				deep_dup(value).each { |v| base_dup.delete(v) }
				base_dup + deep_dup(value)
			elsif base.is_a?(Hash) && value.is_a?(Hash)
				merge_hash(base, value, prepend: false)
			else
				deep_dup(value)
			end
		when :batch_update
			batch_update_items(base, value)
		when :merge
			if base.is_a?(Hash) && value.is_a?(Hash)
				overwrite(base, value)
			elsif value.nil?
				base
			else
				deep_dup(value)
			end
		else
			deep_dup(value)
		end
	end

	def self.apply_set_fields(item, set_values)
		keys_to_delete = []

		set_values.each do |k, v|
			processed_key, operation = parse_key(k)
			result = apply_operation(item[processed_key], v, operation)
			if result.equal?(DELETED_SENTINEL)
				keys_to_delete << processed_key
			else
				item[processed_key] = result
			end
		end

		keys_to_delete.each { |k| item.delete(k) }
	end

	def self.match_item(item, where_conditions, key = nil)
		where_conditions.all? do |k, v|
			if k == 'key' && !key.nil?
				match_value(key, v)
			elsif item.is_a?(Hash)
				match_value(item[k] || item[k.to_s], v)
			elsif item.is_a?(String) && k == 'value'
				match_value(item, v)
			else
				false
			end
		end
	end

	def self.batch_update_items(collection, update_spec)
		return collection unless update_spec.is_a?(Hash)

		begin
			where_conditions = update_spec['where'] || {}
			set_values = update_spec['set'] || {}

			if collection.is_a?(Array)
				result = collection.dup
				delete_indices = []

				result.each_with_index do |item, index|
					match = match_item(item, where_conditions)

					if match
						if item.is_a?(Hash)
							apply_set_fields(item, set_values)
						elsif item.is_a?(String) && set_values.key?('value')
							new_value = set_values['value']
							if new_value.nil?
								delete_indices << index
							else
								result[index] = deep_dup(new_value)
							end
						end
					end
				end

				delete_indices.reverse_each { |i| result.delete_at(i) }
				result
			elsif collection.is_a?(Hash)
				if where_conditions.any? { |k, _| k != 'key' } &&
					match_item(collection, where_conditions)
					result = collection.dup
					apply_set_fields(result, set_values)
					result
				else
					result = collection.dup
					keys_to_delete = []

					result.each do |key, value|
						next unless value.is_a?(Hash)
						match = match_item(value, where_conditions, key)

						if match
							if set_values.key?('key-') || (set_values.key?('key') && set_values['key'].nil?)
								keys_to_delete << key
							else
								apply_set_fields(value, set_values)
							end
						end
					end

					keys_to_delete.each { |k| result.delete(k) }
					result
				end
			elsif collection.nil?
				nil
			else
				collection
			end
		rescue => e
			LOG_ERROR("YAML overwrite failed:【(batch update) => update_spec: %s, error: %s】" % [update_spec, e.message])
			collection
		end
	end
end