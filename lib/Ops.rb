require 'active_support'
require 'builder'
require 'ostruct'
class Ops

  def initialize
    @url_for_new_order        = "http://localhost:3000/requestxmls/receive_xml.xml"
    @url_for_approval_order   = "http://localhost:3000/requestxmls/receive_xml.xml"
  end

  def return_ops_url(ops_template_id,params)
    xml           = create_order(params)
    request       = HTTParty.post(@url_for_new_order,:body => xml.target!, :headers => {'Content-type' => 'text/xml'})
    hash_request  = verify_response(request)
    url           = hash_request['cxml']['Response']['PunchOutSetupResponse']['StartPage']['URL']
  end

  def returns_images_generated params
    xml           = generate_order_approval(params)
    request       = HTTParty.get(@url_for_approval_order, :body => xml, :headers => {'Content-type' => 'text/xml'})
    hash_request  = verify_response(request)
    hash_request['images']
  end

  def create_order params
    dataOps = create_struct(params)
    extrinc = { 'CostCenter'=> dataOps.cost_center_number, 'UserEmail'=> dataOps.employ_email, 'UniqueName'=> dataOps.user_name, 'StartPoint'=> dataOps.start_point }
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.declare! :DOCTYPE, :cXML, :SYSTEM, "http://xml.cXML.org/schemas/cXML/1.2.007/cXML.dtd"
    xml.cxml("playloadID" => "", "timestamp" =>"optional", "version"=>"1.0","xml:lang" => "en") do
      xml.Header do
        xml.From do
          xml.Credential("domain"=>"DUNS") do
            xml.Identity dataOps.duns
          end
        end
        xml.To do
          xml.Credential("domain"=>"DUNS") do
            xml.Identity
          end
        end
        xml.Sender do
          xml.Credential("domain"=> "NetworkUserId") do
            xml.Identity
            xml.SharedSecret dataOps.shared_secret
          end
          xml.UserAgent dataOps.user_agent
        end
      end
      xml.Request("deploymentMode" => "test") do
        xml.PunchOutSetupRequest("operation" => "#{dataOps.status}") do
          xml.BuyerCookie dataOps.buyer_cookie
          extrinc.each do |k,v|
            xml.Extrinsic(v,'name'=> k)
          end
          xml.BrowserFormPost do
            xml.URL dataOps.url_return
          end
          if dataOps.status == "create"
            xml.SelectedItem do
              xml.ItemID do
                xml.SupplierPartID dataOps.template_external_number
              end
            end
          elsif dataOps.status == "edit"
            xml.ItemOut do
              xml.ItemId do
                xml.SupplierPartID dataOps.supplier_part_id
              end
            end
          end
        end
      end
    end
    return xml
  end

  def generate_order_approval params
    dataOps = create_struct(params)
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.Request("type" => "Order","Id" => dataOps.cart_transaction_id, "Date" => dataOps.date_time) do
      xml.Order("Version" => "1.0", "CartNumber" => dataOps.cart_transaction_id, "Date" => dataOps.date_time) do
        xml.DeploymentMode "Production"
        xml.SiteUrl dataOps.url
        xml.comment! "EOI"
        xml.Extrinsic("Type" => dataOps.eoi_caption) do dataOps.eoi_value end
        xml.comment! "/EOI"
        xml.BillTo("CostCenter" => dataOps.cost_centre_number, "CustomerPO" => dataOps.po_number) do
          xml.Payment("Method" => dataOps.cart_type) do
            xml.Charges("Currency" => "USD", "CurrencySymbol" => dataOps.currency_symbol)  do
              xml.Freight("cost" => dataOps.freight)   do dataOps.freight end
              xml.Tax      dataOps.cart_tax
              xml.Total    dataOps.cart_cost
            end
          end
          xml.PostalAddress do
            xml.CompanyName  dataOps.cart_address_company
            xml.name         dataOps.customer_name
            xml.attn         dataOps.cart_attention
            [dataOps.cart_address_1,dataOps.cart_address_2,dataOps.cart_address_3].each do |address|
              xml.Address address
            end
            xml.City          dataOps.cart_city
            xml.StateProv     dataOps.cart_state
            xml.PostalCode    dataOps.cart_zip
            xml.Country       dataOps.cart_country
            xml.ContactPhone  dataOps.cart_address_phone_number
          end
          xml.BillingAddress do
            [dataOps.cart_billing_address1,dataOps.cart_billing_address2,dataOps.cart_billing_address3].each do |cart_address|
              xml.Address cart_address
            end
            xml.City          dataOps.cart_billing_city
            xml.StateProv     dataOps.cart_billing_state
            xml.PostalCode    dataOps.cart_billing_zip
            xml.Country       dataOps.cart_billing_country
          end
          xml.UserAgent dataOps.user_agent
        end
      end
      xml.Request("deploymentMode" => "test") do
        xml.PunchOutSetupRequest("operation" => "#{dataOps.status}") do
          xml.BuyerCookie dataOps.buyer_cookie
          dataOps.extrinc.each do |k,v|
            xml.Extrinsic(v,'name'=> k)
          end
          xml.BrowserFormPost do
            xml.URL dataOps.url_return
          end
          xml.SelectedItem do
            xml.ItemID do
              xml.SupplierPartID dataOps.template_external_number
              xml.Ordered_by do
                xml.FirstName       dataOps.ordered_by_first_name
                xml.LastName        dataOps.ordered_by_last_name
                xml.Phone           dataOps.ordered_by_phone
                xml.Email           dataOps.ordered_by_email
                xml.ExtEmpId        dataOps.ordered_by_ext_emp_id
                xml.AddEmpInfo      dataOps.ordered_by_add_emp_info
                xml.CostCentreName  dataOps.ordered_by_cost_centre_name
                xml.UserName        dataOps.ordered_by_user_name
                xml.comment! "ExtraInputField"
                xml.Extrinsic("Type" => dataOps.extra_input_field_external_name) do dataOps.extra_input_field_name end
                xml.comment! "/ExtraInputField"
              end
              xml.items do

                xml.item("LineNumber" => dataOps.order_number, "Rush" => dataOps.urgent, "type" => dataOps.status_type, "approved" => dataOps.approved,
                         "WaitingScheduler" => dataOps.waiting_scheduler_process) do

                  xml.Supplier                dataOps.supplier_code
                  xml.SupplierPartID          dataOps.deptor_code
                  xml.ManufacturerPartID      dataOps.master_no
                  xml.TemplateName            dataOps.template_name
                  xml.Quantity                dataOps.quantity
                  xml.UnitSize                dataOps.qty_per_unit
                  xml.Image                   dataOps.file
                  xml.ImpositionImage         dataOps.imp_file
                  xml.ShedulerFile            dataOps.sheduler_file
                  xml.FileUpload              dataOps.file_upload
                  xml.FileUploadName          dataOps.file_upload_name
                  xml.comment! "NexJobFiles#{dataOps.order_id}"
                  xml.NexJobFileUpload("filenumber" => dataOps.file_number) do dataOps.nj_file end
                  xml.NexJobFileUploadConverted("filenumber" => dataOps.file_number) do dataOps.njpd_file end
                  xml.comment! "/NexJobFiles#{dataOps.order_id}"
                  xml.TypeSettingInfo          dataOps.type_setting_info
                  xml.TemplateOrderInformation dataOps.other_information
                  xml.ApproverComments         dataOps.approval_approver_comments
                  xml.UserComments             dataOps.individual_comments
                  xml.Project do
                    xml.comment! "Project#{dataOps.order_id}"
                    xml.ProjectName       dataOps.pjct_name
                    xml.UrgentPostage     dataOps.pjct_urgent_postage
                    xml.UploaderList      dataOps.pjct_list_file
                    xml.UploaderListName  dataOps.pjct_list_name
                    xml.ListRecordCount   dataOps.pjct_list_record_count
                    xml.comment! "/Project#{dataOps.order_id}"
                    xml.comment! "ProjectPage#{dataOps.order_id}"
                    xml.ProjectPage("Number" => dataOps.pjct_pg_num, "Name" => dataOps.pjct_pg_name) do
                      xml.NumberPagesinFile     dataOps.pjct_num_of_pgs
                      xml.ProjectPageFile       dataOps.pjct_file
                      xml.ProjectPageQuantity   dataOps.pjct_qty
                      xml.comment! "ProjectEOI#{dataOps.order_id}-#{dataOps.pjct_pg_num}"
                      xml.Extrinsic("Type" => dataOps.project_caption) do dataOps.project_value end
                      xml.comment! "/ProjectEOI#{dataOps.order_id}-#{dataOps.pjct_pg_num}"
                      xml.Extrinsic("Type" => "SupplierCode") do dataOps.supplier_code end
                    end
                    xml.comment! "/ProjectPage#{dataOps.order_id}"
                  end
                  xml.comment! "BackTemplate"
                  xml.BackManufacturerPartID  dataOps.back_master_no
                  xml.BackTemplateName        dataOps.back_template_name
                  xml.BackImage               dataOps.back_file
                  xml.BackImpositionImage     dataOps.back_imp_file
                  xml.comment! "/BackTemplate"
                  xml.Extrinsic("Type" => "NameOnStateonery") do dataOps.stationery_name end
                  xml.comment! "EOI#{dataOps.order_id}"
                  xml.Extrinsic("Type" => dataOps.eoi_caption) do dataOps.eoi_value end
                  xml.comment! "/EOI#{dataOps.order_id}"
                  xml.ShipTo do
                    xml.Carrier  dataOps.freight_type
                    xml.Method   dataOps.freight_method
                    xml.PostalAddress do
                      xml.CompanyName dataOps.order_address_company
                      xml.Name        dataOps.customer_name
                      xml.Attn        dataOps.order_attention
                      [dataOps.order_address_1,dataOps.order_address_2,dataOps.order_address_3].each do |address|
                        xml.Address address
                      end
                      xml.City         dataOps.order_city
                      xml.StateProve   dataOps.order_state
                      xml.PostalCode   dataOps.order_zip
                      xml.Country      dataOps.order_country
                      xml.ContactPhone dataOps.order_address_phone_number
                    end
                  end
                  xml.Charges("Currency" => "USD") do
                    xml.comment! "OrderCost"
                    xml.Item dataOps.order_cost
                    xml.comment! "/OrderCost"
                    xml.comment! "OrderTax"
                    xml.Tax dataOps.order_tax
                    xml.comment! "/OrderTax"
                    xml.comment! "OrderPostage"
                    xml.Postage dataOps.order_postage
                    xml.comment! "/OrderPostage"
                    xml.comment! "OrderTotal"
                    xml.Total dataOps.total_cost
                    xml.comment! "/OrderTotal"
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def punch_out_order
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.declare! :DOCTYPE, :cXML, :SYSTEM, "http://xml.cXML.org/schemas/cXML/1.2.007/cXML.dtd"
    xml.cxml("xml:lang" => "en-US","playloadID" => "", "timestamp" =>"optional") do
      xml.Header do
        xml.From do
          xml.Credential("domain"=>"DUNS")
          xml.Identity "1364789"
        end
        xml.To do
          xml.Credential("domain"=>"DUNS") do
            xml.Identity "1364789"
          end
        end
        xml.Sender do
          xml.Credential("domain"=>"http://localhost:3000") do
            xml.Identity "PunchoutOrderMessage"
          end
          xml.UserAgent "OrderDesk"
        end
      end
      xml.Message do
        xml.PunchoutOrderMessage do
          xml.BuyerCookie "21345"
        end
        xml.PunchOutOrderMessage do
          xml.BuyerCookie "5460"
          xml.PunchOutOrderMessageHeader("operationAllowed" => "inspect") do
            xml.Total do
              xml.Money("currency" => "USD") { "56778" }
            end
          end
          xml.ITEM do
            xml.ItemIn("quantity" => "34") do
              xml.ItemID do
                xml.SupplierPartID "45667"
              end
              xml.ItemDetail do
                xml.UnitPrice do
                  xml.Money("currency" => "AUD"){ "2.8" }
                end
                xml.Description("xml:lang" => "en") { "123.99" }
                xml.UnitOfMeasure "BX"
                xml.Classification("domain" => "UNSPSC") { "1234" }
                xml.Extrinsic("name" => "ImpositionFile") { "Impfile" }
                xml.Extrinsic("name" => "UserFile") { "File" }
                xml.Extrinsic("name" => "BackImpositionFile") { "BackFile" }
                xml.Extrinsic("name" => "BackUserFile") { "BackUserFile" }
              end
            end
          end
        end
      end
    end
  end

  def verify_response response
    response_in_hash = convert_to_hash(response)
    status = response_in_hash['cxml']['Response']['Status']['code']
    return response_in_hash if status == "200"
    "fail"
  end

  def create_struct data
    OpenStruct.new(data)
  end

  def convert_to_xml(hash)
    hash.to_xml.to_s
  end

  def convert_to_hash(xml)
    xml.kind_of?(Hash) ? xml : from_xml(xml)
  end
end
