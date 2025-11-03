#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'sentinel.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find the main target
target = project.targets.find { |t| t.name == 'sentinel' }

# Find the Views group
views_group = project.main_group['sentinel']['Views']

# Check if Components group exists, if not create it
components_group = views_group['Components']
if components_group.nil?
  components_group = views_group.new_group('Components', 'sentinel/Views/Components')
end

# Add AgentTagView.swift if it doesn't exist
file_path = 'sentinel/Views/Components/AgentTagView.swift'
unless components_group.files.any? { |f| f.path == 'AgentTagView.swift' }
  file_ref = components_group.new_file(file_path)
  target.add_file_references([file_ref])
  puts "Added AgentTagView.swift to project"
else
  puts "AgentTagView.swift already exists in project"
end

project.save
puts "Project saved successfully"
