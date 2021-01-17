# Copyright 2021 Bernie Habermeier
# Licensed under the MIT license

require 'sketchup.rb'

module Bolla
  module WindowMaker

    class WindowOpening
      attr_accessor :wall_thickness
      attr_accessor :depth_unit_vector           # vector in direction from inside to outside of window
      attr_accessor :inside_window_mesh          # may be usefull later for constructing window / glass
      attr_accessor :inside_window_outer_loop    # all edges that should still be present after push/pull
      attr_accessor :outside_face

      def to_s
        <<~EOS
        WindowOpening
          wall_thickness: #{@wall_thickness}
          depth_unit_vector: #{@deth_unit_vector}
          inside_window_mesh: #{@inside_window_mesh}
          inside_window_edges: #{@inside_window_edges}, len: #{@inside_window_edges.length}
          outside_face: #{@outside_face}
        EOS
      end
    end

    @@thing = nil
    def self.db
      return @@thing
    end

    # this just punches out a window from a wall for you, so you don't have
    # to manualluy push/pull yourself.  It also returns the a window object
    # that has a few properties, such as wall thickness, original selected
    # edges / active face, and the info of the other side of the window
    # opening.

    # just found raytest randomly... hoping this will do what I want
    def self.punch_out_window_hole
      model = Sketchup.active_model
      model.start_operation('Make Window', true)
      group = model.active_entities.add_group
      entities = model.active_entities

      selection = model.selection
      active_face = selection.find { |entity| entity.class == Sketchup::Face }
      first_vertex = active_face.edges.first.vertices.first
      start_point = first_vertex.position

      # build an edge that goes opposite of the normal of the face (ie: into the wall)
      intersecting_normalized_vector = active_face.normal.reverse.normalize

      ray = [start_point, intersecting_normalized_vector]
      item = model.raytest(ray, false)
      if (!item)
        puts "no other side of the wall found..."
        return false
      end
      @@thing = item
      intersection_point = item[0]
      intersection_component = item[1].last
      wall_thickness = start_point.distance(intersection_point)

      window_opening = WindowOpening.new
      window_opening.wall_thickness = wall_thickness
      window_opening.depth_vector = intersecting_normalized_vector
      window_opening.inside_window_mesh = active_face.mesh
      window_opening.inside_window_edges = active_face.outer_loop
      window_opening.outside_face = intersection_component

      distance = wall_thickness * -1.0
      active_face.pushpull(distance)

      @@thing = window_opening
      return window_opening

    end

    def self.create_window
      model = Sketchup.active_model
      model.start_operation('Make Window', true)
      group = model.active_entities.add_group
      entities = model.active_entities

      window_opening = punch_out_window_hole




      model.commit_operation
    end

    unless file_loaded?(__FILE__)
      menu = UI.menu('Plugins')
      menu.add_item('Make Window') {
        self.create_window
      }
      file_loaded(__FILE__)
    end


  # Reload extension by running this method from the Ruby Console:
  #   Bolla::WindowMaker.reload
  def self.reload
    original_verbose = $VERBOSE
    $VERBOSE = nil
    pattern = File.join(__dir__, '**/*.rb')
    Dir.glob(pattern).each { |file|
      # Cannot use `Sketchup.load` because its an alias for `Sketchup.require`.
      load file
    }.size
  ensure
    $VERBOSE = original_verbose
  end

  end # module WindowMaker
end # module Bolla
