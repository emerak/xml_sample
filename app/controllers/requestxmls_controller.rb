class RequestxmlsController < ApplicationController
  require 'builder'
  def receive_xml
    respond_to do |format|
      format.xml { render :xml => create_xml }
    end
  end

  def create_xml
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.declare! :DOCTYPE, :cXML, :SYSTEM, "http://xml.cXML.org/schemas/cXML/1.2.007/cXML.dtd"
    xml.cxml("xml:lang" => "en-US","playloadID" => "", "timestamp" =>"optional") do
      xml.Response do
        xml.Satus("code" => "200", "text" => "succes")
        xml.PunchOutSetupResponse do
          xml.StartPage do
            xml.URL "http://localhost:3000/mistemplates/1"
          end
        end
      end
    end
  end
end
