Rails.application.routes.draw do
  mount Hyrax::Migrator::Engine => "/hyrax-migrator"
end
