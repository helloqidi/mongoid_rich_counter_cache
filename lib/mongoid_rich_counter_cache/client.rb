# encoding: utf-8
require 'digest/md5'
require 'uri'
require 'net/http'
require 'cgi'


module Lakala

  #使用:
  #@client=Lakala::Client.new({:merid=>"",:mincode=>"",:minpswd=>""})
  class Client
    include ClassUtilMixin


    protected
    #merid:商户号; mincode:固定账单号; minpswd:商户密码
    attr_accessor :merid, :mincode, :minpswd


    public
    #类变量
    @@defaults = {
      :ver => "20060301",
      :expiredtime => 1440,
      :pay_url => "http://www.paygate.cn/MerchantPlugin3/BillNoGenServlet",
      :query_url => "http://pgs.lakala.com.cn/tradeSearch/ndsinglesearch"
    }

    #类变量
    @@config = Lakala::Config.new(@@defaults)

    #类方法
    #使用：
    #Lakala::Client.configure do |conf|
    #  conf.ver=""
    #  conf.expiredtime=1440*2
    #  pay_url=""
    #  query_url=""
    #end
    #可改变类变量@@config的值,如果不改变，则默认通过@@defaults获得默认值
    #
    class << self
      def configure(&block)
        raise ArgumentError, "Block must be provided to configure" unless block_given?
        yield @@config
      end
    end # class << self


    ##
    #返回拉卡拉快捷账单号支付url,根据其指定格式形成url.
    #
    #使用：
    #@client=Lakala::Client.new({:merid=>"",:mincode=>"",:minpswd=>""})
    #@lakala_pay_url=@client.redirect_to_lakala_gateway({
    #  :productname => "product name", 
    #  :desc => "product desc", 
    #  :amount => 100, 
    #  :orderid => "your order id", 
    #  :merurl=> "your website's url when lakala pay success"
    #})
    #
    def redirect_to_lakala_gateway(options={})
      #验证参数
      validate_client_params

      query_hash = {
        #版本号
        :ver=>@@config.ver.to_s,
        #商户号
        :merid=>self.merid.to_s,
        #密码
        :minpswd=>self.minpswd.to_s,
        :orderid=>options[:orderid],
        #金额,单位:分
        :amount=>(options[:amount]*100).to_i.to_s,
        #随机数
        :randnum=>rand(100000..999999).to_s,
        :merurl=>options[:merurl],
        #加密类型MD5
        :mactype=>"2",
        #固定账单号
        :mincode=>self.mincode.to_s
      }

      sign_string=query_hash.collect{|key,value| CGI.unescape(value)}.join("|")+"|"
      #加密
      #无中文,不用转码
      #signature=Digest::MD5.hexdigest(sign_string.force_encoding('GBK'))
      signature=Digest::MD5.hexdigest(sign_string)

      #删除密码
      query_hash.delete(:minpswd)
      query_string=query_hash.merge({
        :mac=>signature,
        :desc=>options[:desc].to_s,
        :mobilenum=>options[:mobilenum].to_s,
        :username=>options[:username].to_s,
        :expiredtime=>@@config.expiredtime.to_s,
        :productname=>options[:productname].to_s
      #}).collect{|key,value| "#{key.upcase}=#{value}"}.join("&")
      }).collect{|key,value| "#{key.upcase}=#{value.force_encoding('GBK')}"}.join("&")

      query_string+="&payUrl=#{''}"
      redirect_string="#{@@config.pay_url}?#{query_string}"
    
      URI.escape(redirect_string)
    end


    ##
    #请求拉卡拉单笔查询,获得返回的文本
    #
    #使用:
    #@client=Lakala::Client.new({:merid=>"",:mincode=>"",:minpswd=>""})
    #@lakala_query_result=@client.http_get_single_query_string({
    #  :order_id=>"your order id",
    #  :order_date=>Time.now.strftime("%Y%m%d")
    #})
    #
    #返回:
    #  @lakala_query_result.connection (判断是否查询成功)
    #  @lakala_query_result.result (Y---支付成功   F—支付未成功 N –订单不存在)
    #  @lakala_query_result.order_id (订单编号)
    #  @lakala_query_result.amount (金额,单位:分)
    #
    def http_get_single_query_string(options={})
      #验证参数
      validate_client_params

      #进行http链接,获得返回的response
      res=http_connect_lakala(redirect_to_single_query(options))

      #拉卡拉返回的格式：
      #account_date|amount|pay_method|mer_id|order_date|order_id|pay_seq|result|ver_id|verify_string
      return_string=res.body

      #拆分文本,获得相关信息
      return_array=return_string.split("|")
      verify_string=return_array[10-1]
      sign_hash={
        :ver_id=>return_array[9-1],
        :mer_id=>return_array[4-1],
        :order_date=>return_array[5-1],
        :order_id=>return_array[6-1],
        #金额,单位:分
        :amount=>return_array[2-1],
        #Y---支付成功   F—支付未成功 N –订单不存在
        :result=>return_array[8-1],
        :mer_key=>self.minpswd.to_s
      }
      #重新加密
      sign_string=sign_hash.collect{|key,value| "#{key}=#{value}"}.join("&")
      signature=Digest::MD5.hexdigest(sign_string)

      #验证签字
      if verify_string==signature
        Lakala::Query.new({:connection=>true,
                          :result=>return_array[8-1],
                          :order_id=>return_array[6-1],
                          :amount=>return_array[2-1]}
                         )      
      else
        Lakala::Query.new({:connection=>false})     
      end
    end


    private
    ##
    #拉卡拉单笔查询的url,根据其指定格式形成url.
    #
    def redirect_to_single_query(options={})
      query_hash = {
        #版本号
        :ver_id=>@@config.ver.to_s,
        #商户号
        :mer_id=>self.merid.to_s,
        #订单的创建时间,格式:YYYYMMDD
        :order_date=>options[:order_date].to_s,
        :order_id=>options[:order_id].to_s,        
        #加密类型MD5
        :mac_type=>"2",
        #密码
        :mer_key=>self.minpswd.to_s
      }

      sign_string=query_hash.collect{|key,value| "#{key}=#{value}"}.join("&")
      signature=Digest::MD5.hexdigest(sign_string)
      
      #删除密码
      query_hash.delete(:mer_key)    
      query_string=query_hash.merge({
        :verify_string=>signature,
        #返回纯文本格式
        :ret_mode=>"1"
      }).collect{|key,value| "#{key}=#{value}"}.join("&")

      redirect_string="http://pgs.lakala.com.cn/tradeSearch/ndsinglesearch?" + query_string
      URI.escape(redirect_string)
    end

    ##
    #进行http链接,获得返回的response
    #
    def http_connect_lakala(url)
      uri = URI(url)
      connection = Net::HTTP.new(uri.host, uri.port)
      response = nil
      connection.start do |http|
        request = Net::HTTP::Get.new(uri.request_uri)
        timeout(15) do
          response = http.request(request)
        end
        handle_rest_response_lakala(response)
        response
      end
    end

    #
    #验证返回的respoonse是否正确
    #
    def handle_rest_response_lakala(response)
      if !response.is_a?(Net::HTTPSuccess)
        raise "get lakala response frm Net::HTTP fail"
      end
    end

    #
    #验证client是否缺少参数
    #
    def validate_client_params
      ["merid","mincode","minpswd"].each do |method|
        value=self.send(method)
        if value.nil?
          raise "Need param:#{method} for client."
        end
      end 
    end

  end#Client class

end
