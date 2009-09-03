require 'gloc'

module MessengerI18nPatch

  def ll(lang, symbol, hash = {})
    translation = GLoc.ll(lang, symbol)
    hash.each do |key, value|
      translation = translation.gsub("{{#{key.to_s}}}", value.to_s)
    end
    translation
  end

  def l(symbol, hash = {})
    translation = GLoc.l(symbol)
    hash.each do |key, value|
      translation = translation.gsub("{{#{key.to_s}}}", value.to_s)
    end
    translation
  end

end
