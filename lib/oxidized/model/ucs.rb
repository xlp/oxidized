class UCS < Oxidized::Model
  prompt /^(\r?[\w.@_()-]+[#]\s?)$/
  comment '! '

  cmd 'show version brief' do |cfg|
    comment cfg
  end

  cmd 'show chassis detail' do |cfg|
    comment cfg
  end

  cmd 'show fabric-interconnect detail' do |cfg|
    comment cfg
  end

  cmd 'show server inventory expand detail | no-more' do |cfg|
    comment cfg
  end

  cmd 'show configuration all | no-more' do |cfg|
    cfg.gsub! /^ !   enter backup.*?exit/m, ''
    cfg.gsub! /^     enter schedule exp-bkup-outdate.*?exit/m, ''
    cfg
  end

  cfg :ssh, :telnet do
    post_login 'terminal length 0'
    pre_logout 'exit'
  end

  cfg :telnet do
    username /^login:/
    password /^Password:/
  end
end
