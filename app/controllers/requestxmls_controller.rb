class RequestxmlsController < ApplicationController
  def receive_xml
    respond_to do |format|
      format.xml { render :xml => "<siteurl>""http://localhost:3000/mistemplates/1""</siteurl>"}
    end
  end
end
