# encoding: utf-8

# Class for handling api for TinyUrls
class Api::TinyUrlsController < ApiController
  before_action :validate_input_url, only: [:create]

  resource_description do
    short 'API for shortening large urls'
  end

  api :POST, '/tiny_url', 'Create TinyUrls'
  description <<-EOS
  == Create TinyUrls
    This API is used to create the tiny urls from large urls.
  EOS
  error code: 200, desc: 'Success Response'
  error code: 400, desc: 'Bad Request'
  param :tiny_url, Hash, description: 'Large Url inputs', required: true do
    param :full_url, String, desc: 'Url need to shorten', required: true
  end

  ##
  # Api For creating tiny url from original url
  def create
    tiny_url = TinyUrl.find_or_initialize(full_url)
    if tiny_url.save
      render status: :ok, json: { shortend_url: shortend_url(tiny_url), message: t('api.tiny_urls.successfully_created') }
    else
      render status: :bad_request, json: { message: tiny_url.errors.full_messages }
    end
  end

  api :GET, '/tiny_url/', 'Get Tiny Urls'
  formats [:json]
  description <<-EOS
  == Display tiny_url
    This API is used for redirecting tiny urls to original urls .
  EOS
  error code: 200, desc: 'Success Response (Redirect to the original site)'
  error code: 400, desc: 'Bad Request'
  error code: 404, desc: 'Not Found'

  ##
  # Api For redirect from tiny url to original url
  def redirect_to_url
    domain = request.original_url
    @tiny_url = TinyUrl.find_by(shortend_url: domain.split('?')[1]) if domain
    if @tiny_url
      full_url = @tiny_url.full_url
      redirect_to full_url
    else
      render status: :not_found, json: { message: t('api.tiny_urls.no_data_found') }
    end
  end

  ##
  # **************************Private Methods*****************************
  private

  def shortend_url(tiny_url)
    host_url + '?' + tiny_url.shortend_url
  end

  def host_url
    request.original_url.split('api')[0]
  end

  ##
  # method for validate input url
  def validate_input_url
    render(status: :bad_request, json: { message: t('api.tiny_urls.invalid_url') }) && return unless tiny_url_params[:full_url] =~ URI.regexp
  end

  ##
  # with per-tiny_url checking of permissible attributes.
  def tiny_url_params
    params.require(:tiny_url).permit(:full_url)
  end

  def full_url
    params[:tiny_url][:full_url]
  end
end
