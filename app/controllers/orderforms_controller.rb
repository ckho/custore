class OrderformsController < ApplicationController
  before_action :set_locale
 
  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end
  def index
    orderform = Orderform.find(id: "apr2017_1st")
    redirect_to orderform
  end

  def show
    @orderform = Orderform.find(id: params[:id])
    if @orderform == nil
      orderform = Orderform.find(id: "apr2017_1st")
      redirect_to orderform
    end
    @producers = @orderform.producers

    client = Google::APIClient.new(application_name: 'CUHKBUY Orderform', application_version: '0.0.1')
    key = Google::APIClient::KeyUtils.load_from_pkcs12(
      '/home/deploy/custore/app/controllers/cuhk-buy-form-28e43eb0cb05.p12',
      'notasecret')
    asserter = Google::APIClient::JWTAsserter.new(
      'orderform@cuhk-buy-form.iam.gserviceaccount.com',
      ['https://www.googleapis.com/auth/drive'],
      key
    )
    client.authorization = asserter.authorize
    session = GoogleDrive.login_with_oauth(client.authorization.access_token)
    ws_options = session.spreadsheet_by_key(@orderform.gid).worksheets[3]
    @enable = ws_options[1,2]
    @ws_products = session.spreadsheet_by_key(@orderform.gid).worksheets[1]

  end

  def form_submit
    orderform = Orderform.find(id: params[:id])
    client = Google::APIClient.new(application_name: 'CUHKBUY Orderform', application_version: '0.0.1')
    key = Google::APIClient::KeyUtils.load_from_pkcs12(
      '/home/deploy/custore/app/controllers/cuhk-buy-form-28e43eb0cb05.p12',
      'notasecret')
    asserter = Google::APIClient::JWTAsserter.new(
      'orderform@cuhk-buy-form.iam.gserviceaccount.com',
      ['https://www.googleapis.com/auth/drive'],
      key
    )
    client.authorization = asserter.authorize
    session = GoogleDrive.login_with_oauth(client.authorization.access_token)
    ws_orders = session.spreadsheet_by_key(orderform.gid).worksheets[0]
    ws_products = session.spreadsheet_by_key(orderform.gid).worksheets[1]
    ws_options = session.spreadsheet_by_key(orderform.gid).worksheets[3]
    out_of_stock = false
    total = 0.0
    for producer in orderform.producers.asc(:display_order).each
      for product in producer.products.asc(:display_order).each
        if ( (ws_products[product.remain_location.to_i, 13].to_i != -1) && (params[product.id.to_sym].to_i > ws_products[product.remain_location.to_i, 13].to_i))
          out_of_stock = true
          break
        else
          total += params[product.id.to_sym].to_i * product.price.to_f
        end
      end
      break if out_of_stock
    end
    if out_of_stock
      render "out_of_stock"
    else
      current_row = ws_orders.num_rows+1
      ws_orders[current_row, 1] = Time.zone.now.strftime("%B %e, %Y at %I:%M %p")
      ws_orders[current_row, 2] = params[:name]
      ws_orders[current_row, 3] = params[:mobile]
      ws_orders[current_row, 4] = params[:email]
      ws_orders[current_row, 5] = params[:college]
      ws_orders[current_row, 6] = params[:cu_resident]
      ws_orders[current_row, 7] = params[:origin]
      ws_orders[current_row, 8] = params[:other]
      ws_orders[current_row, 9] = params[:product_suggestion]
      ws_orders[current_row, 10] = params[:promotion_optin]
      ws_orders[current_row, 11] = total
      for producer in orderform.producers.asc(:display_order).each
        for product in producer.products.asc(:display_order).each
          ws_orders[current_row, product.order_column] = params[product.id.to_sym]
        end
      end
      ws_orders.save
      OrderformAutoreplyMailer.confirm_email(params, total, orderform).deliver_now
      render "success"
    end

  end

  def new

  end
  def create
    if params[:orderform][:pw] = "to-be-filled"
      @orderform = Orderform.new(id: params[:orderform][:id], gid: params[:orderform][:gid])
      I18n.locale = :hk
      @orderform.title = params[:orderform][:title_hk]
      @orderform.text = params[:orderform][:text_hk]
      I18n.locale = :en
      @orderform.title = params[:orderform][:title_en]
      @orderform.text = params[:orderform][:text_en]


      client = Google::APIClient.new(application_name: 'CUHKBUY Orderform', application_version: '0.0.1')
      key = Google::APIClient::KeyUtils.load_from_pkcs12(
        '/home/deploy/custore/app/controllers/cuhk-buy-form-28e43eb0cb05.p12',
        'notasecret')

      asserter = Google::APIClient::JWTAsserter.new(
        'orderform@cuhk-buy-form.iam.gserviceaccount.com',
        ['https://www.googleapis.com/auth/drive'],
        key
      )
      client.authorization = asserter.authorize
      session = GoogleDrive.login_with_oauth(client.authorization.access_token)
      ws_producers = session.spreadsheet_by_key(@orderform.gid).worksheets[2]
      (2..ws_producers.num_rows).each do |row|
        producer = @orderform.producers.new(id: ws_producers[row, 1], display_order: ws_producers[row, 2])
        I18n.locale = :hk
        producer.name = ws_producers[row, 3]
        producer.description = ws_producers[row, 5]
        I18n.locale = :en
        producer.name = ws_producers[row, 4]
        producer.description = ws_producers[row, 6]
        producer.save
      end
      ws_products = session.spreadsheet_by_key(@orderform.gid).worksheets[1]
      (2..ws_products.num_rows).each do |row|
        product = @orderform.producers.find(id: ws_products[row, 1][0]).products.new(id: ws_products[row, 1], display_order: ws_products[row, 2], order_column: ws_products[row, 3], price: ws_products[row, 7].delete( "HK$" ).to_f, remain_location: row)
        I18n.locale = :hk
        product.name = ws_products[row, 5]
        product.unit = ws_products[row, 8]
        product.in_bracket = ws_products[row, 10]
        I18n.locale = :en
        product.name = ws_products[row, 6]
        product.unit = ws_products[row, 9]
        product.in_bracket = ws_products[row, 11]
        product.save
      end
      @orderform.save
      redirect_to @orderform
    end
  end
  def update
    if params[:orderform][:pw] = "to-be-filled"
      @orderform = Orderform.find(id: params[:id])
      @orderform.producers.clear


      client = Google::APIClient.new(application_name: 'CUHKBUY Orderform', application_version: '0.0.1')
      key = Google::APIClient::KeyUtils.load_from_pkcs12(
        '/home/deploy/custore/app/controllers/cuhk-buy-form-28e43eb0cb05.p12',
        'notasecret')

      asserter = Google::APIClient::JWTAsserter.new(
        'orderform@cuhk-buy-form.iam.gserviceaccount.com',
        ['https://www.googleapis.com/auth/drive'],
        key
      )
      client.authorization = asserter.authorize
      session = GoogleDrive.login_with_oauth(client.authorization.access_token)
      ws_producers = session.spreadsheet_by_key(@orderform.gid).worksheets[2]
      (2..ws_producers.num_rows).each do |row|
        producer = @orderform.producers.new(id: ws_producers[row, 1], display_order: ws_producers[row, 2])
        I18n.locale = :hk
        producer.title = ws_producers[row, 3]
        producer.description = ws_producers[row, 5]
        I18n.locale = :en
        producer.title = ws_producers[row, 4]
        producer.description = ws_producers[row, 6]
        producer.save
      end
      ws_products = session.spreadsheet_by_key(@orderform.gid).worksheets[1]
      (2..ws_products.num_rows).each do |row|
        product = @orderform.producers.find(id: ws_products[row, 1][0]).products.new(id: ws_products[row, 1], display_order: ws_products[row, 2], order_column: ws_products[row, 3], price: ws_products[row, 7].delete( "HK$" ).to_f, remain_location: row)
        I18n.locale = :hk
        product.name = ws_products[row, 5]
        product.unit = ws_products[row, 8]
        product.in_bracket = ws_products[row, 10]
        I18n.locale = :en
        product.name = ws_products[row, 6]
        product.unit = ws_products[row, 9]
        product.in_bracket = ws_products[row, 11]
        product.save
      end
      @orderform.save
      redirect_to @orderform
    end
  end
end
