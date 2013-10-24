require 'active_support'
require 'builder'
class Ops
  attr_accessor :duns,:shared_secrete,:user_agent,:buyer_cookie,:cost_center_number,:employ_email,
    :user_name,:template_external_number,:url_return,:order_number, :start_point
  def initialize
    @duns = "12345"
    @shared_secret = "98765"
    @user_agent = "Inkd.com"
    @buyer_cookie = 'user'
    @cost_center_number = "12354"
    @employ_email = "johndoe@inkd.com"
    @user_name = "johndoe"
    @template_external_number = "48098"
    @url_return = "http://localhost:3000/templates"
    @order_number = "78983"
    @status = "create"
    @start_point = ""
    create_new_order
    generate_order_approval
  end

  def return_ops_url(ops_template_id)
    xml = convert_to_xml(:key => ops_template_id)
    request_xml = HTTParty.get("http://localhost:3000/requestxmls/receive_xml.xml",:body => xml, :headers => {'Content-type' => 'text/xml'})
    hash = convert_to_hash(request_xml)
    url = hash['siteurl']
  end

  def create_new_order
  end

  def generate_order_approval
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.Request("type" => "Order","Id" => @cart_transaction_id, "Date" => @date_time) do
      xml.Order("Version" => "1.0", "CartNumber" => @cart_transaction_id, "Date" => @date_time) do
        xml.DeploymentMode "Production"
        xml.SiteUrl @url
        xml.comment! "EOI"
          xml.Extrinsic("Type" => @eoi_caption) do @eoi_value end
        xml.comment! "/EOI"
        xml.BillTo("CostCenter" => @cost_centre_number, "CustomerPO" => @po_number) do
          xml.Payment("Method" => @cart_type) do
            xml.Charges("Currency" => "USD", "CurrencySymbol" => @currency_symbol)  do
              xml.Freight("cost" => @freight)   do @freight end
              xml.Tax                           @cart_tax
              xml.Total                         @cart_cost
            end
          end
          xml.PostalAddress do
            xml.CompanyName  @cart_address_company
            xml.name         @customer_name
            xml.attn         @cart_attention
            [@cart_address_1,@cart_address_2,@cart_address_3].each do |address|
              xml.Address address
            end
            xml.City          @cart_city
            xml.StateProv     @cart_state
            xml.PostalCode    @cart_zip
            xml.Country       @cart_country
            xml.ContactPhone  @cart_address_phone_number
          end
          xml.BillingAddress do
            [@cart_billing_address1,@cart_billing_address2,@cart_billing_address3].each do |cart_address|
              xml.Address cart_address
            end
            xml.City          @cart_billing_city
            xml.StateProv     @cart_billing_state
            xml.PostalCode    @cart_billing_zip
            xml.Country       @cart_billing_country
          end
          xml.Ordered_by do
            xml.FirstName       @ordered_by_first_name
            xml.LastName        @ordered_by_last_name
            xml.Phone           @ordered_by_phone
            xml.Email           @ordered_by_email
            xml.ExtEmpId        @ordered_by_ext_emp_id
            xml.AddEmpInfo      @ordered_by_add_emp_info
            xml.CostCentreName  @ordered_by_cost_centre_name
            xml.UserName        @ordered_by_user_name
            xml.comment! "ExtraInputField"
              xml.Extrinsic("Type" => @extra_input_field_external_name) do @extra_input_field_name end
            xml.comment! "/ExtraInputField"
          end
          xml.items do
            xml.item("LineNumber" => @order_number, "Rush" => @urgent, "type" => @status_type, "approved" => @approved, "WaitingScheduler" => @waiting_scheduler_process) do
              xml.Supplier                @supplier_code
              xml.SupplierPartID          @deptor_code
              xml.ManufacturerPartID      @master_no
              xml.TemplateName            @template_name
              xml.Quantity                @quantity
              xml.UnitSize                @qty_per_unit
              xml.Image                   @file
              xml.ImpositionImage         @imp_file
              xml.ShedulerFile            @sheduler_file
              xml.FileUpload              @file_upload
              xml.FileUploadName          @file_upload_name
              xml.comment! "NexJobFiles#{@order_id}"
                xml.NexJobFileUpload("filenumber" => @file_number) do @nj_file end
                xml.NexJobFileUploadConverted("filenumber" => @file_number) do @njpd_file end
              xml.comment! "/NexJobFiles#{@order_id}"
              xml.TypeSettingInfo          @type_setting_info
              xml.TemplateOrderInformation @other_information
              xml.ApproverComments         @approval_approver_comments
              xml.UserComments             @individual_comments
              xml.Project do
                xml.comment! "Project#{@order_id}"
                  xml.ProjectName       @pjct_name
                  xml.UrgentPostage     @pjct_urgent_postage
                  xml.UploaderList      @pjct_list_file
                  xml.UploaderListName  @pjct_list_name
                  xml.ListRecordCount   @pjct_list_record_count
                xml.comment! "/Project#{@order_id}"
                xml.comment! "ProjectPage#{@order_id}"
                  xml.ProjectPage("Number" => @pjct_pg_num, "Name" => @pjct_pg_name) do
                    xml.NumberPagesinFile     @pjct_num_of_pgs
                    xml.ProjectPageFile       @pjct_file
                    xml.ProjectPageQuantity   @pjct_qty
                    xml.comment! "ProjectEOI#{@order_id}-#{@pjct_pg_num}"
                      xml.Extrinsic("Type" => @project_caption) do @project_value end
                    xml.comment! "/ProjectEOI#{@order_id}-#{@pjct_pg_num}"
                    xml.Extrinsic("Type" => "SupplierCode") do @supplier_code end
                  end
                xml.comment! "/ProjectPage#{@order_id}"
              end
              xml.comment! "BackTemplate"
                xml.BackManufacturerPartID  @back_master_no
                xml.BackTemplateName        @back_template_name
                xml.BackImage               @back_file
                xml.BackImpositionImage     @back_imp_file
              xml.comment! "/BackTemplate"
              xml.Extrinsic("Type" => "NameOnStateonery") do @stationery_name end
              xml.comment! "EOI#{@order_id}"
                xml.Extrinsic("Type" => @eoi_caption) do @eoi_value end
              xml.comment! "/EOI#{@order_id}"
              xml.ShipTo do
                xml.Carrier  @freight_type
                xml.Method   @freight_method
                xml.PostalAddress do
                  xml.CompanyName @order_address_company
                  xml.Name        @customer_name
                  xml.Attn        @order_attention
                  [@order_address_1,@order_address_2,@order_address_3].each do |address|
                    xml.Address address
                  end
                  xml.City         @order_city
                  xml.StateProve   @order_state
                  xml.PostalCode   @order_zip
                  xml.Country      @order_country
                  xml.ContactPhone @order_address_phone_number
                end
              end
              xml.Charges("Currency" => "USD") do
                xml.comment! "OrderCost"
                  xml.Item @order_cost
                xml.comment! "/OrderCost"
                xml.comment! "OrderTax"
                  xml.Tax @order_tax
                xml.comment! "/OrderTax"
                xml.comment! "OrderPostage"
                  xml.Postage @order_postage
                xml.comment! "/OrderPostage"
                xml.comment! "OrderTotal"
                  xml.Total @total_cost
                xml.comment! "/OrderTotal"
              end
            end
          end
        end
      end
    end
  end

  def return_shoopingcart_xml(ops_template_id)
  end

  def convert_to_xml(hash)
    hash.to_xml.to_s
  end

  def convert_to_hash(xml)
    xml.kind_of?(Hash) ? xml : from_xml(xml)
  end
end
