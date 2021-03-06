class StaffsController < ApplicationController
 before_action :basic_auth, if: :production?
 before_action :staff_id_check, only: [:edit, :update, :destroy]
    
    def index
        @staffs = Staff.recent
        @name = '名前'
        @age = '年齢'
        @gender = '性別'
        @status = '階級'
    end
    
    
    def new
        @staff = Staff.new
        
        date = Date.today
        staffIds = Staff.pluck(:id)
        
        if staffIds.present?
            @staff_number = "推奨ナンバー#{date.year}00#{staffIds.last + 1}"
        else
            @staff_number = "推奨ナンバー#{date.year}001"
        end
    end
    
    
    def create
        @staff = Staff.new(staff_params)
        if @staff.save
            flash[:notice] = '社員登録完了しました。'
            redirect_to staffs_path
        else 
            flash.now[:alert] = '社員登録完了していません。'
            render :new
        end
    end
    
    
    def edit
        @staff = searchStaffId
        @staff_image = @staff.image
    end
    

    def update
        
        #else以下が実行された場合 renderが発動するので@staffにしておけば、勝手staffでーたを飛ばしてくれます。
        @staff = searchStaffId

        @staff.assign_attributes(staff_params)
        
        if @staff.save
            flash[:notice] = '社員情報を編集しました。'
            redirect_to staffs_path
            
        else
            flash.now[:alert] = '社員情報を編集できていません。'
            render :edit
            
        end
    end
    
    
    def destroy
        staff = searchStaffId
        staff.destroy
        redirect_to staffs_path
            

    end

    private
        def staff_params
             params.require(:staff).permit(:last_name, :first_name, :last_name_kana, :first_name_kana, :number, :age, :gender,
                                           :experience, :status, :self_introduction, :image)
        end


        def staff_id_check
            staff = searchStaffId
            
            if staff.nil?
                flash[:alert] = 'スタッフが存在しません。'
                redirect_to root_path
                
            end
        end
        
        def searchStaffId
            
            Staff.find_by(id: params[:id])
            
        end
end
