require_relative 'external_includes'

def as_class_name table_name
  table_name.to_s.singularize.capitalize.to_sym
end
