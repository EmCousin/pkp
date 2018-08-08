class ApplicationMailer < ActionMailer::Base
  default from: 'inscriptions@parkourparis.fr'
  layout 'mailer'

  def confirm_subscription(params)
    @first_name = params[:firstName]
    @current_year = params[:currentYear]
    @next_year = params[:nextYear]
    pdf = WickedPdf.new.pdf_from_string(
      render_to_string 'templates/pdf.html.erb', layout: 'pdf.html.erb',
                                                 encoding: 'UTF-8',
                                                 locals: {
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

    )

    attachments['fiche.pdf'] = { mime_type: 'application/pdf', content: pdf.force_encoding('UTF-8') }

    mail to: params[:email], subject: "Inscription Parkour Paris #{params[:currentYear]} / #{params[:nextYear]}"
  end
end
