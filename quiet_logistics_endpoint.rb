Dir['./lib/**/*.rb'].each { |f| require f }

class QuietLogisticsEndpoint < EndpointBase::Sinatra::Base

  set :logging, true

  before do
    AWS.config(access_key_id: @config['amazon_access_key'],
               secret_access_key: @config['amazon_secret_key']) if request.request_method == 'POST'
  end

  post '/get_messages' do
    begin
      queue = @config['ql_incoming_queue']

      receiver = Receiver.new(queue)
      receiver.receive_messages { |msg| add_object :message, msg }

      message  = "recevied #{receiver.count} messages"
      code     = 200
    rescue => e
      message  = e.message
      code     = 500
    end

    result code, message
  end

  post '/get_data' do
    begin
      bucket = @config['ql_incoming_bucket']
      msg    = @payload['message']
      data   = Processor.new(bucket).process_doc(msg)

      if data.type == :unknown
        message = "Cannot handle document of type #{msg['document_type']}"
      else
        add_object(data.type.to_sym, data.to_h)
        message  = "Got Data for #{msg['document_name']}"
      end

      code = 200
    rescue => e
      message  = e.message
      code     = 500
    end

    result code, message
  end

  post '/add_shipment' do
    begin
      shipment = @payload['shipment']
      message  = Api.send_document('ShipmentOrder', shipment, outgoing_bucket, outgoing_queue, @config)
      code     = 200
    rescue => e
      message = e.message
      code    = 500
    end

    result code, message
  end

  post '/add_purchase_order' do
    begin
      order   = @payload['purchase_order']
      message = Api.send_document('PurchaseOrder', order, outgoing_bucket, outgoing_queue, @config)
      code    = 200
    rescue => e
      message = e.message
      code    = 500
    end

    result code, message
  end

  post '/add_product' do
    begin
      item    = @payload['product']
      message = Api.send_document('ItemProfile', item, outgoing_bucket, outgoing_queue, @config)
      code    = 200
    rescue => e
      message = e.message
      code    = 500
    end

    result code, message
  end

  post '/add_rma' do
    begin
      shipment = @payload['rma']
      message  = Api.send_document('RMADocument', shipment, outgoing_bucket, outgoing_queue, @config)
      code     = 200
    rescue => e
      message  = e.message
      code     = 500
    end

    result code, message
  end

  def outgoing_queue
    @config['ql_outgoing_queue']
  end

  def outgoing_bucket
    @config['ql_outgoing_bucket']
  end
end