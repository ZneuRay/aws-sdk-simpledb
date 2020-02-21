module Aws::SimpleDB
  # @api private
  class MetadataHandler < Seahorse::Client::Handler

    include Seahorse::Model::Shapes

    CONTENT_TYPE = 'application/x-www-form-urlencoded; charset=utf-8'

    WRAPPER_STRUCT = ::Struct.new(:result, :response_metadata)

    METADATA_STRUCT = ::Struct.new(:request_id, :box_usage)

    METADATA_REF = begin
      request_id = ShapeRef.new(
        shape: StringShape.new,
        location_name: 'RequestId')
      box_usage = ShapeRef.new(
        shape: StringShape.new,
        location_name: 'BoxUsage')
      response_metadata = StructureShape.new
      response_metadata.struct_class = METADATA_STRUCT
      response_metadata.add_member(:request_id, request_id)
      response_metadata.add_member(:box_usage, box_usage)
      ShapeRef.new(shape: response_metadata, location_name: 'ResponseMetadata')
    end

    # @param [Seahorse::Client::RequestContext] context
    # @return [Seahorse::Client::Response]
    def call(context)
      @handler.call(context).on_success do |response|
        parse_xml(context)
      end
    end

    private

    def parse_xml(context)
      data = Aws::Xml::Parser.new(rules(context)).parse(xml(context))
      remove_wrapper(data, context)
    end

    def xml(context)
      context.http_response.body_contents
    end

    def rules(context)
      shape = Seahorse::Model::Shapes::StructureShape.new
      if context.operation.output
        shape.add_member(:result, ShapeRef.new(
          shape: context.operation.output.shape,
          location_name: context.operation.name + 'Result'
        ))
      end
      shape.struct_class = WRAPPER_STRUCT
      shape.add_member(:response_metadata, METADATA_REF)
      ShapeRef.new(shape: shape)
    end

    def remove_wrapper(data, context)
      if context.operation.output
        if data.response_metadata
          context[:request_id] = data.response_metadata.request_id
          context[:box_usage] = data.response_metadata.box_usage
        end
      end
    end

  end
end
