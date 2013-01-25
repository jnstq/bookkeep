class Bookkeep

  class Config
    def self.description
      ENV['bookeep_voucher_description']
    end

    def self.account_in
      ENV['bookeep_account_in']
    end

    def self.account_vat
      "2410"
    end    

    def self.account_system
      ENV['bookeep_account_system']
    end
  end

  def self.process(orders)
    Array(orders).each { |order| Bookkeep.new(order).perform }
  end

  attr_reader :order

  def initialize(order)
    @order = order
  end

  def perform
    Fortnox::Voucher.create(attributes).tap do |voucher_id|
      order.update_attribute(:voucher_id, voucher_id)
      order.update_attribute(:voucher_last_error, last_error)
    end
  end

  private

  def attributes
    {
      :descr  => "#{Config.description} #{order.class}##{order.id}",
      :images => images,
      :tdate  => paid_on,
      :posts  => posts
    }
  end

  def posts
    [
      { :post => { :account => Config.account_in,     :deb => order.bookkeep_amount                   } },
      { :post => { :account => Config.account_vat,    :cre => order.bookkeep_amount.tax_amount(:vat)  } },
      { :post => { :account => Config.account_system, :cre => order.bookkeep_amount.exclude_tax(:vat) } },
    ]    
  end

  def images
    order.line_items.map(&:preview_url).compact.map do |url|
      { :image => { :link => Rack::Utils.escape(url) } }
    end
  end

  def paid_on
    I18n.l(order.paid_at, :format => "%Y-%m-%d")
  end

  def last_error
    Fortnox::Voucher.last_response.try(:[],'error').try(:[], 'message')
  end

end