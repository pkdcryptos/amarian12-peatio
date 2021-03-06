require 'spec_helper'

describe TwoFactorsController do
  describe 'GET :show' do
    let(:member) { create :member, :sms_two_factor_activated }
    before { session[:member_id] = member.id }

    let(:do_request) { get :show, {id: :sms, refresh: true} }

    it {
      AMQPQueue.expects(:enqueue).with(:sms_notification, anything)
      do_request
    }
  end

  describe 'GET :index' do
    context 'member without two_factor' do
      let(:member) { create :member }
      before { session[:member_id] = member.id }

      before { get :index }

      it { expect(response).to redirect_to(settings_path) }
    end

    context 'member with sms_two_factor activated' do
      let(:member) { create :member, :sms_two_factor_activated }
      before { session[:member_id] = member.id }

      before { get :index }

      it { expect(response).to be_ok }
      it { expect(response).to render_template('index') }
    end
  end

  describe 'PUT :update' do
    let(:member) { create :member, :sms_two_factor_activated }

    context 'with wrong otp' do
      let(:attrs) { { id: :sms,
                      two_factor: { type: :sms,
                                    otp: 'wrong code' } } }

      before {
        session[:member_id] = member.id
        put :update, attrs
      }

      it { expect(response).to redirect_to(two_factors_path) }
      it { expect(flash[:alert]).to match('verification code error') }
    end

    context 'with right otp' do
      let(:attrs) { { id: :sms,
                      two_factor: { type: :sms,
                                    otp: member.sms_two_factor.otp_secret } } }

      before {
        session[:member_id] = member.id
        put :update, attrs
      }

      it { expect(response).to redirect_to(settings_path) }
      it { expect(session[:two_factor_unlock]).to be_true }
      it { expect(session[:two_factor_unlock_at]).not_to be_blank }
    end
  end
end
