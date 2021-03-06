class ReservationsController < ApplicationController
    
 before_action :basic_auth, only: [:search, :index], if: :production?
 
 #createアクションが呼ばれたら、menuIds, staffId, framesは空になっている。
 before_action :nil_check_menus, only: [:choosen_menus, :choose_staff, :choosen_staff, :choose_date]   
 before_action :nil_check_staff, only: [:choosen_staff, :choose_date] 
 before_action :update_passedTimes, only: [:choose_date]
 before_action :nil_check_something, only: [:custamer_detail]
 before_action :reservation_params, only: [:create]

#--------------検索-----------------  
    def search
        #@staffs = Staff.all.order(status: :asc)
        @name = '担当スタッフ名前'
        
        date = Date.current
        twoMonthLater =  date + 2.month
        #今日から予約のできる2ヶ月後まで
        @dates = (date..twoMonthLater)
        
        @searchedReservations = Reservation.search(params[:search_tel], params[:search_date], @dates)
    end
    
    
    def index
        @name = '担当スタッフ名前'
        end_this_month = Date.current.end_of_month
        d = (Date.current..end_this_month)
        
        #今日から今月末まで
        #searchDateはreservationのscope
        this_month_reservations = Reservation.searchDate(d).order(date: :asc)
        
        #全体  activeはscope 
        after_this_month_reservations = Reservation.active.order(date: :desc)
        
        mixed_reservations = this_month_reservations | after_this_month_reservations
        @reservations = mixed_reservations.uniq
        
    
    end
    
#-----------------------Reservation-------------------------    
    
    def choose_menus
        
        @reservation = Reservation.new
        
        @menus = Menu.where(category: 1)
        @menus2 = Menu.where(category: 2)
        @menus3 = Menu.where(category: 3)
        @menus4 = Menu.where(category: 4)
        @menus5 = Menu.where(category: 5)
        @menus6 = Menu.where(category: 6)
        
        @haircut = 'カット'
        @colour = 'カラー'
        @curl = 'パーマ'
        @treatment = 'トリートメント'
        @setting_your_hair = 'ヘアセット'
        @other = 'その他'
        
    end
    
    
    def choosen_menus
        menuIds = menuIds_params

        if menuIds.present?
            #javascriptで returnをして飛べないようにしてます。
            redirect_to controller: 'reservations', action: 'choose_staff', menus: menuIds_params
        else
            #render :choose_menus
            redirect_to choose_menus_path and return
        end
    end
    
    
    def choose_staff
        selectedMenus = menuIds_params

        #recentはstaff.rbにscopeとして書いている。
        @staffs = Staff.recent
        
        @name = '名前'
        @age = '年齢'
        @gender = '性別'
        @status = '階級'
        
        #view用
        @menuIds =  menuIds_params
        

#---------------------メニュー----------------------
        menus = selectedMenus.map{|menuId|totalMenus(menuId)}
        
        #privateの一番した
        combination(menus)

    end
    
    
    def choose_date
        #paramsで受け取ると文字列になる。
        @menuIds = menuIds_params
        staffId = staffId_params
#-----------redirect_to backした場合。---------------------
        keepFrames = params[:frame]
        keepDate = params[:date]
        
        #custamer_detail以降から戻ってきた時keep -> available
        if keepFrames.present? && keepDate
            keepFrames.each do |keepFrame|
               schedule = Schedule.find_by(staff_id: staffId, 
                                           date: keepDate, 
                                           frame: keepFrame, 
                                           frame_status: 'keep')
                if schedule     
                    schedule.update(frame_status: 'available')
                end
            end
        end
        
#---------------ブラウザバックからのリロード対策---------------        
        #custamer_detailからブラウザバック時のリロード対策
        if params[:scheduleIds]
            params[:scheduleIds].each do |scheduleId|
                schedule = Schedule.find_by(id: scheduleId)
                schedule.update(frame_status: "available")
                
            end
        end
        
#----------------------------------------------------------       
        #先週と来週の日数
        receivedNext = params[:next_week]
        receivedPrev = params[:previous_week]
        
        @staff = Staff.find(staffId)
    
#-------------メニュー-----------------------
        #pravateメソッド下さんからメソッド呼び出し。
        menus = @menuIds.map{|menuId|totalMenus(menuId)}
        
        #privateの一番した
        combination(menus)

#-------------先週、翌週のbtn対策--------------
        #@dの条件文(先週なのか翌週なのかで表示する一週間を変更)
        if receivedNext
            @d = Date.parse(receivedNext)
            #logger.debug("------d=#{@d}")
            #date= Date.parse(receivedNext)
        elsif receivedPrev && Date.parse(receivedPrev) < Date.current  #elsifの順番
            @d = Date.current      #- 2.day
        elsif receivedPrev
            @d = Date.parse(receivedPrev)
        else 
            @d = Date.current
        end
         @next = @d + 1.week #aタグ用
         @prev = @d - 1.week #aタグ用
    end
    
    
    
    def custamer_detail
        # linkからの受け取り
        @date = params[:date]
        @staffId = staffId_params
        @menuIds = menuIds_params
        
        #必要時間
        menuRequiredTimes = params[:menu_required_times]
        
#---------frame_statusのupdateメカニズム---------------  
        if  menuRequiredTimes 
            #必要時間をFloat化して30（３０分単位)でわる。
            number = menuRequiredTimes.to_f/30
            toInteger = number.to_i
             
            #updateNumbeはupdateするDBの行数。 　10min, 15min, 30min,でも１つはupdateする。
            #30分以下
            if toInteger < 1
                 updateNumber = 1
                #Integerのアルゴリズム toIntegerが割り切れるのであればその整数がupdateNumbeはupdateするDBのカラム数。
                #numberは必要時間をFloat化して30（３０分単位)で割った値つまりfloatである。下記の二つのあまりを求めることであまりが０ならintegerでなけばfloat
                
            elsif 0 == number % toInteger        
            
                updateNumber = toInteger
            else
                #少数アルゴリズム　else以下に入れるnumberはFloatなので + 1しupdateするカラム数にあわせる。
                #つまり1.2ならDBの2行update
                #必要時間75minならnumberは2.5である。2.5に+1して3.5にして.to_iで3つupdateする。
                number_float = number + 1                   
                updateNumber =  number_float.to_i
            end
                #updateNumbeはupdateするDBのカラム数。
            selectedSchedule =  Schedule.find_by(staff_id: @staffId, date: params[:date], frame: params[:frame])      #選択された日程からidを割り出す。
           
            #updateしたカラムにおけるFrameを取得
            
            @frames=[]  
            
            #Javascriptへ直渡し
            @scheduleIds=[]
            
            #iは0から始まり
            updateNumber.times do |i|      
                #一週目は初めのselectedScheduleのidを取得
                
                scheduleId = selectedSchedule.id + i
                
                schedule = Schedule.find_by(id: scheduleId)
                
                schedule.update(frame_status: "keep")
                
                @frames.push(schedule.frame)
                
                @scheduleIds.push(schedule.id)
            end
            
            #---------------------------------------------
            #frameとメニューのvalueは配列、hash化してネストさせる。
            @hash_frames = {key_frames: @frames}
            @hash_menuIds = {key_menuIds: @menuIds}
            #@hash_framesと@hash_menuIdsをJSON文字列にして@reservationに入れとく。renderのとき楽
            @reservation = Reservation.new(staff_id:  @staffId, date: @date, menu_ids: @hash_menuIds.to_json, frames: @hash_frames.to_json)
        else
            
            #確認画面(confirm)の戻るボタンを押した場合の処理
            @reservation = Reservation.new(reservation_params)
            
            #配列で入ったやつをviewに出せるように変更
            @frames = json_to_hash_frames
            @menuIds = json_to_hash_menuIds
        end
    end
    
    

    def confirm
        @reservation = Reservation.new(reservation_params)
        
        if @reservation.valid?
            #確認画面　表示
            @date = Date.parse(@reservation.date)
            @check = '初来店' if @reservation.check == 'true'
            @check = '再来店' if @reservation.check == 'false'
            @staff = Staff.find_by(id: @reservation.staff_id)
           
            #privateメソッド内json_to_hash_framesメソッドで呼び出し。    
            @frames = json_to_hash_frames
            
    #---------------------メニュー-------------------------------------   
            #privateメソッド内json_to_hash_menuIdsメソッド下で呼び出し。  
            menus = json_to_hash_menuIds.map{|menuId|totalMenus(menuId)}
            
            #privateの一番した
            combination(menus)
            
        else
            #配列@reservation.errors.messagesにはvalidationのエラーメッセージが入っているがredirect＿toで戻していいるから表示されない。
            #log 
            #@reservation.errors.messages={:last_name=>["can't be blank"], :first_name=>["can't be blank"],
            #:last_name_kana=>["can't be blank", "全角カタカナのみで入力して下さい。"],
            #:first_name_kana=>["can't be blank", "全角カタカナのみで入力して下さい。"],
            #:tel=>["can't be blank", "電話番号はハイフンなしです。"], :email=>["can't be blank", "適切なアドレスを入れてください。"]}

            @reservation.errors.full_messages.each do |array_errors_message|
                case array_errors_message
                
                    when "Last nameを入力してください" then
                        
                        flash.now[:alert] = '(性)が未記入です。'
                        
                    when "First nameを入力してください" then
                
                        flash.now[:alert] = '(名)が未記入です。'
                        
                    when "Last name kanaを入力してください" then
                
                        flash.now[:alert] ='性(カナ)が未記入です。' 
                        
                    when "Last name kana全角カタカナのみで入力して下さい。" then
                
                        flash.now[:alert] ='性(カナ)を全角カタカナのみで入力して下さい。'  
                        
                    when "First name kanaを入力してください" then
                        
                        flash.now[:alert] ='性(カナ)が未記入です。' 
                        
                    when "First name kana全角カタカナのみで入力して下さい。" then
                        
                        flash.now[:alert] = '性(カナ)を全角カタカナのみで入力して下さい。' 
                        
                    when "Telを入力してください" then
                        
                        flash.now[:alert] ='電話番号が未記入です。' 
                        
                    when "Tel電話番号はハイフンなしです。" then
                        
                        flash.now[:alert] ='電話番号はハイフンなしです。' 
                    
                     when "Emailを入力してください" then
                        
                        flash.now[:alert] ='メールアドレスが未記入です。' 
                        
                    when "Email適切なアドレスを入れてください。" then
                        
                        flash.now[:alert] ='適切なアドレスを入れてください。'
                end
            end
            render :custamer_detail
        end
    end
    
    def create
        #logger.debug("--------reservation_params=#{reservation_params}")
        #logger.debug("--------hash_frames.class=#{hash_frames.class}")
        #logger.debug("--------hash_frames.class=#{hash_menuIds.class}")
        #logger.debug("--------hash_frames=#{hash_frames}")
        #logger.debug("--------array_frames=#{array_frames}")
        #logger.debug("--------array_menuIds=#{array_menuIds} ")
        
        @reservation = Reservation.new(staff_id: reservation_params[:staff_id],
                                        date: reservation_params[:date],
                                        last_name: reservation_params[:last_name],
                                        first_name: reservation_params[:first_name],
                                        last_name_kana: reservation_params[:last_name_kana],
                                        first_name_kana: reservation_params[:first_name_kana],
                                        tel: reservation_params[:tel],
                                        email: reservation_params[:email],
                                        check: reservation_params[:check],
                                        gender: reservation_params[:gender],
                                        request: reservation_params[:request],
                                        frames: json_to_hash_frames, 
                                        menu_ids: json_to_hash_menuIds)   ##privateメソッド下で呼び出し。  
        if params[:back]
            #logger.debug("-----------------")
            @reservation.frames = {key_frames: json_to_hash_frames}.to_json
            @reservation.menu_ids = {key_menuIds: json_to_hash_menuIds}.to_json
            
            render :custamer_detail
            
        elsif @reservation.save
            #staffのスケジュールを保留keepからreservedへ    
            reservedFrams = JSON.parse(@reservation.frames)
            
            reservedFrams.each do |reservedFrame|
                schedules = Schedule.find_by(staff_id: @reservation.staff_id, 
                                          date: @reservation.date, 
                                          frame: reservedFrame, 
                                          frame_status: 'keep')
                if schedules
                    schedules.update(frame_status: "reserved")
                else
                    flash[:notice] = '時間時れです。もう一度選んでください。'
                    redirect_to choose_menus_reservations_path and return
                end
            end
            
            flash[:notice] ='予約が確定しました。ありがとうございました。'
            redirect_to root_path
            
        else
            flash.now[:alert] = '記入が漏れがあります。'
            render :custamer_detail and return
            
            #redirect_back(fallback_location: fallback_location)
        end
    end
    

    def destroy
        reservation = Reservation.find_by(id: params[:id])
        if reservation
        #scheduleも一緒にupdateする。
        reservedFrams = JSON.parse(reservation.frames)
            reservedFrams.each do |reservedFrame|
                schedules = Schedule.find_by(staff_id: reservation.staff_id, 
                                          date: reservation.date, 
                                          frame: reservedFrame, 
                                          frame_status: 'reserved')
                                          
                schedules.update(frame_status: "available")
            end
            
            reservation.destroy
            flash[:notice] = '予約を削除しました。'
            redirect_to :back
        else
            
            flash[:alert] = '予約が見つかりません。'
            redirect_to :back
            
        end
    end
    
#------------------------------------------------------private--------------------------------------   
    private
        
        def menuIds_params
            params[:menus]
        end
        
        def staffId_params
            params[:selectedStaff]
        end
        
#-------------before_actionシリーズ---URL直打ちを防ぐ------------------
        def nil_check_menus
            if menuIds_params == nil 
            
                flash[:alert] = 'メニューを選択してください。'
                redirect_to choose_menus_reservations_path
            
            end
        end
        
        
        def nil_check_staff
            if staffId_params == nil
            
                flash[:alert] = 'スタッフを選択してください。'
                redirect_to choose_staff_reservations_path(menus: menuIds_params)
                
            end
        end
        
        #urlにreservation/custamer_detailを直打ちされると "param is missing or the value is empty: reservation" のエラーが出ちゃうから対策
        def nil_check_something
            if menuIds_params == nil && params.fetch(:reservation, {}) == {}
                
                flash[:alert] = 'メニューを選択してください。'
                redirect_to choose_menus_reservations_path

                
            elsif  staffId_params == nil && params.fetch(:reservation, {}) == {}
                
                flash[:alert] = 'スタッフを選択してください。'
                redirect_to choose_staff_reservations_path(menus: menuIds_params)
                
            elsif params[:date] == nil && params.fetch(:reservation, {}) == {}
                
                flash[:alert] = '選び直してください。'
                redirect_to choose_menus_reservations_path
                
            end
        end
        
     
        
#-------------------------json文字列変換-----------------------       
        
        def json_to_hash_frames
            
                #JSON文字列で受け取りhashとして扱いvalueを必要な形に崩していく
                #framesのJSON文字列{key_frames: @frames}をparseしてhashとして扱えるようにする。
                hash_frames = JSON.parse(reservation_params[:frames], {symbolize_names: true})
                #hash　:key_framesのvalueを取得
                array_frames = hash_frames[:key_frames]
    
            return array_frames
            
        end
        
        def json_to_hash_menuIds
                
            #framesのJSON文字列{key_menuIds: @menuIds}をparseしてhashとして扱えるようにする。
            hash_menuIds = JSON.parse(reservation_params[:menu_ids], {symbolize_names: true})
            #配列を取得
            array_menuIds = hash_menuIds[:key_menuIds]

            return array_menuIds
        
        end
        
#-------------------------------------------------------
        #当日、fame_statusがavailableのカラム（時間帯）があっても、現在時刻を過ぎていたらをupdateする
        def update_passedTimes

            #JSCで日付を検索  
            #staffId_paramsの呼び出し
            #currentとavailable scope使った。 schedule.rbに記載s
            schedules = Schedule.where(staff_id: staffId_params).current.available

            schedules.each do |schedule|
                #日本時間で(日本の)現在時刻とDBを比較。現在時刻よりも小さいのであればupdate
                if Time.zone.parse(schedule.frame) < Time.current

                    schedule.update_attributes(frame_status: 'break')
                
                end#if
            end##each
        end
            
        #ストロングパラメータは制限かけてるですーー
        def reservation_params
            params.require(:reservation).permit(:staff_id, :last_name, :first_name, :last_name_kana, :first_name_kana, :tel,
                                                :email, :gender, :request, :check, :date, :frames, :menu_ids
                                                )
        end

#------------------------------------menu----------------------------------------


        def totalMenus(menuId)
            menu = Menu.find_by(id: menuId)
            return menu
        end
        
        #まとめた, choose_staff, choose_date, confirmで使った
        def combination(menus)
            
            names = menus.map{|menu| menu.name}
            prices = menus.map{|menu| menu.price}
            required_times = menus.map{|menu| menu.required_time}
            
            #各文字列をintegerにして合計金額と時間を出す。
            prices_integer = prices.map{|x| x.to_i}
            required_times_integer = required_times.map{|y| y.to_i}
        
            #文字列をまとめる
            @menuNames = names.join(',')
            #合計
            @menuPrices = prices_integer.sum
            @menuRequiredTimes = required_times_integer.sum
            
        end

end
