class OrderformAutoreplyMailer < ApplicationMailer
  default from: 'cuhk.buy@gmail.com'
  def confirm_email(params, total, orderform)
    @params = params
    @total = total
    @orderform = orderform
    @producers = @orderform.producers
    email_with_name = %("#{@params[:name]}" <#{@params[:email]}>)
    mail(to: email_with_name, subject: t('email.subject'))
  end
end
