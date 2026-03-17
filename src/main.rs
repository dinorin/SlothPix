#![windows_subsystem = "windows"]
extern crate native_windows_gui as nwg;
extern crate native_windows_derive as nwd;

use anyhow::{anyhow, Result};
use clap::Parser;
use image::{imageops::FilterType, DynamicImage, GenericImageView, RgbaImage};
use nwd::NwgUi;
use nwg::NativeUi;
use ort::session::{builder::GraphOptimizationLevel, Session};
use rayon::prelude::*;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::{mpsc, Arc, Mutex};
use walkdir::WalkDir;
use winrt_notification::{Sound, Toast};

const MODEL_BYTES: &[u8] = include_bytes!("../assets/model.onnx");

#[derive(Parser)]
struct Cli {
    #[arg(short, long)]
    path: String,
}

#[derive(Default, NwgUi)]
pub struct SlothPixProgress {
    #[nwg_resource(family: "Segoe UI", size: 16)]
    font: nwg::Font,

    #[nwg_control(size: (440, 140), position: (300, 300), title: "SlothPix: AI Processing...", flags: "WINDOW|VISIBLE")]
    #[nwg_events( OnWindowClose: [SlothPixProgress::exit_app] )]
    window: nwg::Window,

    #[nwg_control(text: "Preparing...", font: Some(&data.font), size: (420, 30), position: (10, 20))]
    label: nwg::Label,

    #[nwg_control(size: (420, 25), position: (10, 60), range: 0..100)]
    progress_bar: nwg::ProgressBar,

    #[nwg_control(parent: window, interval: 100, stopped: false)]
    #[nwg_events(OnTimerTick: [SlothPixProgress::update_ui])]
    timer: nwg::Timer,

    receiver: Mutex<Option<mpsc::Receiver<(usize, String)>>>,
    total_files: Mutex<usize>,
    current_count: Mutex<usize>,
}

impl SlothPixProgress {
    fn exit_app(&self) {
        nwg::stop_thread_dispatch();
    }

    fn update_ui(&self) {
        let mut current = self.current_count.lock().unwrap();
        let total = *self.total_files.lock().unwrap();
        
        if let Some(rx) = &*self.receiver.lock().unwrap() {
            while let Ok((count, name)) = rx.try_recv() {
                *current = count;
                self.label.set_text(&format!("Processing ({} / {}): {}", count, total, name));
                let percentage = if total > 0 { (count as f32 / total as f32 * 100.0) as u32 } else { 0 };
                self.progress_bar.set_pos(percentage);
            }
        }

        if total > 0 && *current >= total {
            nwg::stop_thread_dispatch();
        }
    }
}

fn main() -> Result<()> {
    let args = Cli::parse();
    let input_path = PathBuf::from(&args.path);

    let files: Vec<PathBuf> = if input_path.is_file() {
        vec![input_path.clone()]
    } else if input_path.is_dir() {
        WalkDir::new(&input_path).into_iter().filter_map(|e| e.ok())
            .filter(|e| {
                let ext = e.path().extension().and_then(|s| s.to_str()).unwrap_or("").to_lowercase();
                matches!(ext.as_str(), "jpg"|"jpeg"|"png"|"webp")
            })
            .map(|e| e.path().to_path_buf())
            .collect()
    } else {
        return Err(anyhow!("Invalid path!"));
    };

    if files.is_empty() { return Ok(()); }
    let total = files.len();

    nwg::init().map_err(|e| anyhow!("GUI Init error: {:?}", e))?;
    let ui_data = SlothPixProgress::default();
    *ui_data.total_files.lock().unwrap() = total;
    
    let (tx, rx) = mpsc::channel();
    *ui_data.receiver.lock().unwrap() = Some(rx);
    
    let _ui = SlothPixProgress::build_ui(ui_data).map_err(|e| anyhow!("UI Build error: {:?}", e))?;

    std::thread::spawn(move || {
        let session_result: Result<Session> = (|| {
            // Khởi tạo môi trường ONNX Runtime (Bắt buộc cho phiên bản mới)
            let _ = ort::init()
                .with_name("SlothPix")
                .commit();

            let session = Session::builder()
                .map_err(|e| anyhow!("{}", e))?
                .with_optimization_level(GraphOptimizationLevel::Level3)
                .map_err(|e| anyhow!("{}", e))?
                // Thử dùng GPU (DirectML), nếu thất bại sẽ tự động dùng CPU
                .with_execution_providers([ort::execution_providers::DirectMLExecutionProvider::default().build()])
                .map_err(|e| anyhow!("{}", e))?
                .commit_from_memory(MODEL_BYTES)
                .map_err(|e| anyhow!("{}", e))?;
            Ok(session)
        })();

        if let Ok(session) = session_result {
            let session_mutex = Arc::new(Mutex::new(session));
            let counter = Arc::new(Mutex::new(0));

            files.par_iter().for_each(|path| {
                let mut session_lock = session_mutex.lock().unwrap();
                let _ = process_image(&mut *session_lock, path);
                
                let mut c = counter.lock().unwrap();
                *c += 1;
                let _ = tx.send((*c, path.file_name().unwrap().to_string_lossy().to_string()));
            });
        }
        
        let _ = Toast::new(Toast::POWERSHELL_APP_ID)
            .title("SlothPix: Finished!")
            .text1(&format!("Successfully processed {} images.", total))
            .sound(Some(Sound::IM))
            .show();
    });

    nwg::dispatch_thread_events();
    Ok(())
}

fn process_image(session: &mut Session, path: &Path) -> Result<PathBuf> {
    let img = image::open(path)?;
    let (width, height) = img.dimensions();
    let resized = img.resize_exact(1024, 1024, FilterType::Triangle).to_rgb8();

    let mut data = Vec::with_capacity(3 * 1024 * 1024);
    for c in 0..3 {
        for y in 0..1024 {
            for x in 0..1024 {
                let pixel = resized.get_pixel(x as u32, y as u32);
                let val = match c {
                    0 => (pixel[0] as f32 / 255.0 - 0.485) / 0.229,
                    1 => (pixel[1] as f32 / 255.0 - 0.456) / 0.224,
                    _ => (pixel[2] as f32 / 255.0 - 0.406) / 0.225,
                };
                data.push(val);
            }
        }
    }

    let input_tensor = ort::value::Value::from_array((vec![1, 3, 1024, 1024], data))
        .map_err(|e| anyhow!("Tensor error: {}", e))?;
    
    let outputs = session.run(ort::inputs![input_tensor])
        .map_err(|e| anyhow!("Inference error: {}", e))?;
    
    let mask_tensor = outputs[0].try_extract_tensor::<f32>().map_err(|e| anyhow!("Extract error: {}", e))?;

    let mut mask_rgba = RgbaImage::new(1024, 1024);
    let mask_data = mask_tensor.1;
    for y in 0..1024 {
        for x in 0..1024 {
            let alpha = (mask_data[y * 1024 + x].clamp(0.0, 1.0) * 255.0) as u8;
            mask_rgba.put_pixel(x as u32, y as u32, image::Rgba([255, 255, 255, alpha]));
        }
    }
    
    let mask_resized = DynamicImage::ImageRgba8(mask_rgba).resize_exact(width, height, FilterType::Triangle);
    let mut final_img = img.to_rgba8();
    for (x, y, pixel) in final_img.enumerate_pixels_mut() {
        pixel[3] = mask_resized.get_pixel(x, y)[3];
    }

    let result_dir = path.parent().unwrap_or_else(|| Path::new(".")).join("SlothPix_Result");
    if !result_dir.exists() { fs::create_dir_all(&result_dir)?; }
    let output_path = result_dir.join(format!("{}_no_bg.png", path.file_stem().unwrap().to_str().unwrap()));
    final_img.save(&output_path)?;

    Ok(output_path)
}
