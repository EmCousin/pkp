class PdfsController < ApplicationController
  protect_from_forgery with: :null_session

  def index
    pdf = WickedPdf.new.pdf_from_string(
      render_to_string 'templates/pdf.html.erb', layout: 'pdf.html.erb',
                                                 encoding: 'UTF-8',
                                                 locals: {
                                                   first_name: params[:firstName],
                                                   last_name: params[:lastName] || '',
                                                   avatar_url: params[:avatarUrl] || params[:avatarPath] || '',
                                                   current_year: params[:currentYear],
                                                   next_year: params[:nextYear],
                                                   courses: params[:courses],
                                                   date_of_birth: params[:dateOfBirth],
                                                   citizenship: params[:citizenship],
                                                   address: params[:address],
                                                   zip_code: params[:zipCode],
                                                   city: params[:city],
                                                   country: params[:country],
                                                   phone_number: params[:phoneNumber],
                                                   cellphone_number: params[:cellphoneNumber],
                                                   email: params[:email],
                                                   contact_person_name: params[:contactPersonName],
                                                   contact_relationship: params[:contactRelationship],
                                                   contact_phone_number: params[:contactPhoneNumber],
                                                   agreed_to_publicity_right: params[:agreedToPublicityRight],
                                                   fee: params[:fee]
                                                 }

    )

    save_path = Rails.root.join('pdfs','filename.pdf')
    file = Tempfile.open(['fiche', '.pdf']) do |f|
      f <<  pdf.force_encoding('UTF-8')
    end

    respond_to do |format|
      format.html do
        send_file file.path, type: 'application/pdf',
                             disposition: 'attachment'
      end
    end
  end

  def notify
    ApplicationMailer.confirm_subscription(params).deliver_now
    render 'templates/pdf', locals: {
                                      first_name: params[:firstName],
                                      last_name: params[:lastName] || '',
                                      avatar_url: params[:avatarUrl] || '',
                                      current_year: params[:currentYear],
                                      next_year: params[:nextYear],
                                      courses: params[:courses],
                                      date_of_birth: params[:dateOfBirth],
                                      citizenship: params[:citizenship],
                                      address: params[:address],
                                      zip_code: params[:zipCode],
                                      city: params[:city],
                                      country: params[:country],
                                      phone_number: params[:phoneNumber],
                                      cellphone_number: params[:cellphoneNumber],
                                      email: params[:email],
                                      contact_person_name: params[:contactPersonName],
                                      contact_relationship: params[:contactRelationship],
                                      contact_phone_number: params[:contactPhoneNumber],
                                      agreed_to_publicity_right: params[:agreedToPublicityRight],
                                      fee: params[:fee]
                                    }
  end
end
