class UrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?
    default_message = "#{value} #{I18n.t('errors.messages.invalid_url')}"

    unless value =~ %r{\Ahttps?:\/\/(.*)}i
      record.errors[attribute] << (options[:message] || default_message)
    end
  end
end
